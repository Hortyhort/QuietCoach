// SubscriptionManager.swift
// QuietCoach
//
// StoreKit 2 subscription management. Clean, async-first API.
// Includes offline resilience with cached status and retry logic.

import StoreKit
import OSLog
import Observation

@Observable
@MainActor
final class SubscriptionManager {

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthlyPro = "com.quietcoach.pro.monthly"
        case yearlyPro = "com.quietcoach.pro.yearly"

        var isSubscription: Bool { true }
    }

    // MARK: - Subscription Status

    enum SubscriptionStatus: Equatable, Sendable {
        case unknown
        case notSubscribed
        case subscribed(expirationDate: Date?, productId: String)
        case expired
        case inGracePeriod(expirationDate: Date)
        case inBillingRetry

        var isActive: Bool {
            switch self {
            case .subscribed, .inGracePeriod, .inBillingRetry:
                return true
            case .unknown, .notSubscribed, .expired:
                return false
            }
        }

        var localizedDescription: String {
            switch self {
            case .unknown: return L10n.SubscriptionStatus.unknown
            case .notSubscribed: return "Free"
            case .subscribed: return L10n.SubscriptionStatus.active
            case .expired: return L10n.SubscriptionStatus.expired
            case .inGracePeriod: return "Grace Period"
            case .inBillingRetry: return "Billing Issue"
            }
        }
    }

    // MARK: - Cached Status (for offline support)

    struct CachedSubscriptionStatus: Codable {
        let isActive: Bool
        let productId: String?
        let expirationDate: Date?
        let cachedAt: Date

        var isStale: Bool {
            Date().timeIntervalSince(cachedAt) > 24 * 60 * 60 // 24 hours
        }

        var isExpired: Bool {
            guard let expiration = expirationDate else { return false }
            return expiration < Date()
        }
    }

    // MARK: - Observable State

    private(set) var products: [Product] = []
    private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var isUsingCachedStatus: Bool = false
    private(set) var cachedStatusIsStale: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Subscriptions")
    private let cacheKey = "com.quietcoach.subscription.cached"

    @ObservationIgnored
    private nonisolated(unsafe) var transactionListenerTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        loadCachedStatus()
        startTransactionListener()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Cache Management

    /// Load cached subscription status for instant UI
    private func loadCachedStatus() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedSubscriptionStatus.self, from: data)
        else {
            logger.debug("No cached subscription status found")
            return
        }

        // Use cached status for immediate UI
        if cached.isActive && !cached.isExpired {
            if let productId = cached.productId {
                subscriptionStatus = .subscribed(expirationDate: cached.expirationDate, productId: productId)
            }
            isUsingCachedStatus = true
            cachedStatusIsStale = cached.isStale

            if cached.isStale {
                logger.info("Using stale cached subscription status")
            } else {
                logger.info("Using cached subscription status")
            }

            // Update feature gates with cached status
            FeatureGates.shared.updateProStatus(true)
        }
    }

    /// Save subscription status to cache
    private func cacheStatus(_ status: SubscriptionStatus) {
        let cached: CachedSubscriptionStatus

        switch status {
        case .subscribed(let expiration, let productId):
            cached = CachedSubscriptionStatus(
                isActive: true,
                productId: productId,
                expirationDate: expiration,
                cachedAt: Date()
            )
        case .inGracePeriod(let expiration):
            cached = CachedSubscriptionStatus(
                isActive: true,
                productId: nil,
                expirationDate: expiration,
                cachedAt: Date()
            )
        case .inBillingRetry:
            cached = CachedSubscriptionStatus(
                isActive: true,
                productId: nil,
                expirationDate: nil,
                cachedAt: Date()
            )
        default:
            cached = CachedSubscriptionStatus(
                isActive: false,
                productId: nil,
                expirationDate: nil,
                cachedAt: Date()
            )
        }

        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            logger.debug("Subscription status cached")
        }

        isUsingCachedStatus = false
        cachedStatusIsStale = false
    }

    // MARK: - Product Loading

    /// Load available products from App Store
    func loadProducts() async {
        guard products.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        // Check network status
        guard NetworkMonitor.shared.status.isConnected else {
            logger.info("Offline - skipping product load")
            errorMessage = L10n.Errors.networkError
            isLoading = false
            return
        }

        do {
            // Use retry logic for network resilience
            let storeProducts = try await NetworkMonitor.shared.withRetry {
                let productIds = ProductID.allCases.map { $0.rawValue }
                return try await Product.products(for: productIds)
            }

            products = storeProducts.sorted { first, second in
                // Monthly first, then yearly
                if first.id.contains("monthly") { return true }
                if second.id.contains("monthly") { return false }
                return first.price < second.price
            }

            logger.info("Loaded \(self.products.count) products")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            errorMessage = "Unable to load subscription options. Please try again."
        }

        isLoading = false
    }

    // MARK: - Purchase

    /// Purchase a subscription product
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                logger.info("Purchase successful: \(product.id)")
                isLoading = false
                return true

            case .userCancelled:
                logger.info("User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                logger.info("Purchase pending approval")
                errorMessage = "Purchase pending approval. Check with your account holder."
                isLoading = false
                return false

            @unknown default:
                logger.warning("Unknown purchase result")
                isLoading = false
                return false
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            errorMessage = "Purchase failed. Please try again."
            isLoading = false
            throw error
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            logger.info("Purchases restored successfully")
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            errorMessage = "Unable to restore purchases. Please try again."
        }

        isLoading = false
    }

    // MARK: - Subscription Status

    /// Check and update current subscription status
    /// Uses cached status when offline, with graceful degradation
    func updateSubscriptionStatus() async {
        var foundActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerification(result)

                if transaction.productType == .autoRenewable {
                    let status = await determineSubscriptionStatus(for: transaction)
                    subscriptionStatus = status

                    // Cache the verified status
                    cacheStatus(status)

                    if status.isActive {
                        foundActiveSubscription = true
                        await updateFeatureGates(isActive: true)
                        logger.info("Active subscription found: \(transaction.productID)")
                        break
                    }
                }
            } catch {
                logger.error("Transaction verification failed: \(error.localizedDescription)")
            }
        }

        if !foundActiveSubscription {
            subscriptionStatus = .notSubscribed
            cacheStatus(.notSubscribed)
            await updateFeatureGates(isActive: false)
        }
    }

    /// Verify subscription with offline fallback
    func verifySubscription() async -> SubscriptionStatus {
        // Check network status
        if !NetworkMonitor.shared.status.isConnected {
            // Offline - use cached status with warning
            if subscriptionStatus.isActive {
                logger.info("Offline - using cached subscription status")
                isUsingCachedStatus = true
                return subscriptionStatus
            }
        }

        // Online - verify with App Store
        await updateSubscriptionStatus()
        return subscriptionStatus
    }

    // MARK: - Transaction Listener

    private func startTransactionListener() {
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                do {
                    let transaction = try self.checkVerification(result)
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                } catch {
                    // Verification failed, ignore this transaction
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }

    // MARK: - Status Determination

    private func determineSubscriptionStatus(for transaction: Transaction) async -> SubscriptionStatus {
        guard let expirationDate = transaction.expirationDate else {
            return .subscribed(expirationDate: nil, productId: transaction.productID)
        }

        // Check subscription renewal info for detailed status
        if let productId = ProductID(rawValue: transaction.productID) {
            do {
                let statuses = try await Product.SubscriptionInfo.status(for: productId.rawValue)

                for status in statuses {
                    if case .verified(let renewalInfo) = status.renewalInfo {
                        // Check for grace period
                        if renewalInfo.gracePeriodExpirationDate != nil {
                            if let gracePeriodDate = renewalInfo.gracePeriodExpirationDate {
                                return .inGracePeriod(expirationDate: gracePeriodDate)
                            }
                        }

                        // Check for billing retry
                        if renewalInfo.isInBillingRetry == true {
                            return .inBillingRetry
                        }
                    }
                }
            } catch {
                logger.error("Failed to get subscription status: \(error.localizedDescription)")
            }
        }

        // Standard subscription check
        if expirationDate > Date() {
            return .subscribed(expirationDate: expirationDate, productId: transaction.productID)
        } else {
            return .expired
        }
    }

    // MARK: - Feature Gates Integration

    private func updateFeatureGates(isActive: Bool) async {
        FeatureGates.shared.updateProStatus(isActive)
    }

    // MARK: - Helpers

    /// Get the formatted price for a product
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    /// Get subscription period description
    func periodDescription(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .day:
            return subscription.subscriptionPeriod.value == 1 ? "daily" : "every \(subscription.subscriptionPeriod.value) days"
        case .week:
            return subscription.subscriptionPeriod.value == 1 ? "weekly" : "every \(subscription.subscriptionPeriod.value) weeks"
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "monthly" : "every \(subscription.subscriptionPeriod.value) months"
        case .year:
            return subscription.subscriptionPeriod.value == 1 ? "yearly" : "every \(subscription.subscriptionPeriod.value) years"
        @unknown default:
            return ""
        }
    }

    /// Whether a product offers a free trial
    func hasFreeTrial(for product: Product) -> Bool {
        product.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    /// Free trial duration description
    func freeTrialDescription(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }

        let period = offer.period
        switch period.unit {
        case .day:
            return period.value == 1 ? "1 day free" : "\(period.value) days free"
        case .week:
            return period.value == 1 ? "1 week free" : "\(period.value) weeks free"
        case .month:
            return period.value == 1 ? "1 month free" : "\(period.value) months free"
        case .year:
            return period.value == 1 ? "1 year free" : "\(period.value) years free"
        @unknown default:
            return nil
        }
    }
}
