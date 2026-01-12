// ShareCardView.swift
// QuietCoach
//
// The shareable rehearsal card. Gorgeous, minimal, no personal content.
// Designed for iMessage and Stories at 1080x1350.

import SwiftUI

struct ShareCardView: View {

    // MARK: - Properties

    let session: RehearsalSession
    var showWatermark: Bool = true

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section: Logo and date
                topSection

                Spacer()

                // Middle section: Scenario and highlight
                middleSection

                Spacer()

                // Bottom section: Watermark
                if showWatermark {
                    bottomSection
                }
            }
            .padding(32)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                LinearGradient(
                    colors: [
                        Color(white: 0.08),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .aspectRatio(1080.0 / 1350.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Top Section

    private var topSection: some View {
        HStack {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.qcSurface)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.qcAccent)
                )

            Spacer()

            // Date
            Text(session.createdAt.qcMediumString)
                .font(.qcCaption)
                .foregroundColor(.qcTextTertiary)
        }
    }

    // MARK: - Middle Section

    private var middleSection: some View {
        VStack(spacing: 32) {
            // Scenario
            if let scenario = session.scenario {
                VStack(spacing: 12) {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.qcAccent)

                    Text(scenario.title)
                        .font(.qcTitle)
                        .foregroundColor(.qcTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Practiced")
                        .font(.qcCaption)
                        .foregroundColor(.qcTextTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
            }

            // Highlight
            VStack(spacing: 10) {
                Text("Highlight")
                    .font(.qcCaption)
                    .foregroundColor(.qcTextTertiary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(highlightText)
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            // Duration
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text(session.formattedDuration)
                    .font(.qcSubheadline)
            }
            .foregroundColor(.qcTextTertiary)
        }
    }

    private var highlightText: String {
        if let winNote = session.coachNotes.first(where: { $0.title == "What worked" }) {
            return winNote.body
        }
        if let note = session.coachNotes.first {
            return note.body
        }
        return "Rehearsed with calm, focused delivery."
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        HStack {
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 10, weight: .medium))

                Text("Quiet Coach")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.qcTextTertiary.opacity(0.6))
        }
    }
}

// MARK: - Share Card Export

extension ShareCardView {
    /// Render the card to a UIImage for sharing
    @MainActor
    func renderToImage(size: CGSize = CGSize(width: 1080, height: 1350)) -> UIImage {
        let renderer = ImageRenderer(content:
            self.frame(width: size.width, height: size.height)
        )
        renderer.scale = 1.0

        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Share Card Settings

struct ShareCardSettings {
    var showWatermark: Bool = true
    var showDate: Bool = true

    static let `default` = ShareCardSettings()
}

// MARK: - Watermark Toggle View

struct WatermarkToggleView: View {
    @AppStorage("shareCard.showWatermark") private var showWatermark = true

    var body: some View {
        Toggle("Include watermark", isOn: $showWatermark)
            .font(.qcBody)
            .tint(.qcAccent)
    }
}

// MARK: - Preview

#Preview("Share Card") {
    VStack {
        ShareCardView(
            session: {
                let session = RehearsalSession(
                    scenarioId: "set-boundary",
                    duration: 127,
                    audioFileName: "test.m4a"
                )
                return session
            }()
        )
        .frame(width: 270, height: 337.5)
        .qcCardShadow()
    }
    .padding()
    .background(Color.qcBackground)
}
