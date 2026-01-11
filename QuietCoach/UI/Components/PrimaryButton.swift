// PrimaryButton.swift
// QuietCoach
//
// The call to action. Bold, confident, tactile.

import SwiftUI

struct PrimaryButton: View {

    // MARK: - Style

    enum Style {
        case filled
        case outline
    }

    // MARK: - Properties

    let title: String
    var icon: String?
    var style: Style = .filled
    var isLoading: Bool = false
    let action: () -> Void

    // MARK: - State

    @State private var isPressing = false

    // MARK: - Body

    var body: some View {
        Button {
            guard !isLoading else { return }
            Haptics.buttonPress()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(title)
                        .font(.qcButton)
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.mediumCornerRadius, style: .continuous))
            .overlay {
                if style == .outline {
                    RoundedRectangle(cornerRadius: Constants.Layout.mediumCornerRadius, style: .continuous)
                        .stroke(Color.qcAccent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressing ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressing = true }
                .onEnded { _ in isPressing = false }
        )
        .opacity(isLoading ? 0.7 : 1.0)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .black
        case .outline:
            return .qcAccent
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return .qcAccent
        case .outline:
            return .clear
        }
    }

    // MARK: - Convenience Initializers

    init(_ title: String, icon: String? = nil, style: Style = .filled, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.buttonPress()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }

                Text(title)
                    .font(.qcButtonSmall)
            }
            .foregroundColor(.qcTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.qcSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Primary Buttons") {
    VStack(spacing: 20) {
        PrimaryButton("Get Started") {}

        PrimaryButton("Share Result", icon: "square.and.arrow.up", style: .outline) {}

        PrimaryButton("Loading...", isLoading: true) {}

        SecondaryButton(title: "Cancel", icon: "xmark") {}
    }
    .padding()
    .background(Color.qcBackground)
}
