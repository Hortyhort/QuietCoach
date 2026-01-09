// ProUpgradeView.swift
// QuietCoach
//
// The Pro pitch. Honest about value, no dark patterns.
// Now with StoreKit 2 integration.

import SwiftUI
import StoreKit

struct ProUpgradeView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(FeatureGates.self) private var featureGates

    // MARK: - State

    @State private var selectedProduct: Product?
    @State private var errorMessage: String?
    @State private var showingError = false

    // MARK: - Computed

    private var subscriptionManager: SubscriptionManager {
        featureGates.subscriptions
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    Spacer(minLength: 32)

                    // Pricing
                    pricingSection
                }
                .padding(.horizontal, 24)
            }
            .background(Color.qcBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.qcTextTertiary)
                    }
                }
            }
            .task {
                await subscriptionManager.loadProducts()
                // Select monthly by default
                selectedProduct = subscriptionManager.products.first
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .onChange(of: featureGates.isPro) { _, isPro in
                if isPro {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Quiet Coach Pro")
                .font(.qcTitle)
                .foregroundColor(.qcTextPrimary)

            Text("Unlock your full potential")
                .font(.qcBody)
                .foregroundColor(.qcTextSecondary)
        }
        .padding(.top, 24)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(
                icon: "rectangle.stack.fill",
                title: "More Scenarios",
                description: "Access all 12 scenarios including negotiations, endings, and confrontations."
            )

            featureRow(
                icon: "clock.fill",
                title: "Unlimited History",
                description: "Keep all your rehearsal sessions, not just the last 10."
            )

            featureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Progress Tracking",
                description: "See how your scores improve over time. (Coming soon)"
            )

            featureRow(
                icon: "waveform.badge.plus",
                title: "Deeper Feedback",
                description: "Word-level analysis with optional transcription. (Coming soon)"
            )
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.qcBodyMedium)
                    .foregroundColor(.qcTextPrimary)

                Text(description)
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 16) {
            if subscriptionManager.isLoading && subscriptionManager.products.isEmpty {
                ProgressView()
                    .padding()
            } else if subscriptionManager.products.isEmpty {
                Text("Unable to load subscription options")
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)

                Button("Try Again") {
                    Task {
                        await subscriptionManager.loadProducts()
                    }
                }
            } else {
                // Product selection
                VStack(spacing: 12) {
                    ForEach(subscriptionManager.products, id: \.id) { product in
                        productOption(product)
                    }
                }

                // Subscribe button
                PrimaryButton(
                    "Subscribe",
                    isLoading: subscriptionManager.isLoading
                ) {
                    Task {
                        await purchase()
                    }
                }
                .disabled(selectedProduct == nil)

                // Restore purchases
                Button {
                    Task {
                        await featureGates.restorePurchases()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.qcSubheadline)
                        .foregroundColor(.qcTextSecondary)
                }
            }
        }
        .padding(.bottom, 48)
    }

    // MARK: - Product Option

    private func productOption(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isMonthly = product.id.contains("monthly")

        return Button {
            selectedProduct = product
            Haptics.selectScenario()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isMonthly ? "Monthly" : "Yearly")
                            .font(.qcBodyMedium)
                            .foregroundColor(.qcTextPrimary)

                        if !isMonthly {
                            Text("Save 58%")
                                .font(.qcCaption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }

                    if let trialDesc = subscriptionManager.freeTrialDescription(for: product) {
                        Text(trialDesc)
                            .font(.qcCaption)
                            .foregroundColor(.qcAccent)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.qcBodyMedium)
                        .foregroundColor(.qcTextPrimary)

                    Text(subscriptionManager.periodDescription(for: product))
                        .font(.qcCaption)
                        .foregroundColor(.qcTextSecondary)
                }
            }
            .padding(16)
            .background(isSelected ? Color.qcAccent.opacity(0.1) : Color.qcSurfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.qcAccent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase

    private func purchase() async {
        guard let product = selectedProduct else { return }

        do {
            let success = try await subscriptionManager.purchase(product)
            if !success {
                // User cancelled or pending — no error needed
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    ProUpgradeView()
        .environment(FeatureGates.shared)
}
