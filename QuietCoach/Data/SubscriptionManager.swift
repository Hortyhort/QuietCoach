// SubscriptionManager.swift
// QuietCoach
//
// StoreKit 2 subscription management. Clean, async-first API.

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
    }

    // MARK: - Observable State

    private(set) var products: [Product] = []
    private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Subscriptions")
    @ObservationIgnored
    private nonisolated(unsafe) var transactionListenerTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        startTransactionListener()
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from App Store
    func loadProducts() async {
        guard products.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let productIds = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)

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
    func updateSubscriptionStatus() async {
        var foundActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerification(result)

                if transaction.productType == .autoRenewable {
                    let status = await determineSubscriptionStatus(for: transaction)
                    subscriptionStatus = status

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
            await updateFeatureGates(isActive: false)
        }
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
