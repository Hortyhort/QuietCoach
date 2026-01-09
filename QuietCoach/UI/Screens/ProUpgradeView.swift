// ProUpgradeView.swift
// QuietCoach
//
// The Pro pitch. Honest about value, no dark patterns.

import SwiftUI

struct ProUpgradeView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var isLoading = false

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
            VStack(spacing: 4) {
                Text("$19.99 / month")
                    .font(.qcTitle2)
                    .foregroundColor(.qcTextPrimary)

                Text("or $99.99 / year (save 58%)")
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
            }

            PrimaryButton("Subscribe", isLoading: isLoading) {
                // TODO: StoreKit purchase flow
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }

            Button {
                // TODO: Restore purchases
            } label: {
                Text("Restore Purchases")
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
            }
        }
        .padding(.bottom, 48)
    }
}

// MARK: - Preview

#Preview {
    ProUpgradeView()
}
