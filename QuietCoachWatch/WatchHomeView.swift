// WatchHomeView.swift
// QuietCoachWatch
//
// Main watch interface. Quick scenarios, recent scores, streak.

import SwiftUI

struct WatchHomeView: View {
    
    // MARK: - State
    
    @State private var selectedScenario: WatchScenario?
    @State private var currentStreak: Int = 0
    @State private var lastScore: Int?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Streak badge
                    streakSection
                    
                    // Quick practice scenarios
                    scenarioSection
                    
                    // Last session
                    if let score = lastScore {
                        lastSessionSection(score: score)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Quiet Coach")
            .sheet(item: $selectedScenario) { scenario in
                WatchRehearseView(scenario: scenario)
            }
        }
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            
            Text("\(currentStreak)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Scenario Section
    
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Practice")
                .font(.headline)
            
            ForEach(WatchScenario.allCases) { scenario in
                Button {
                    selectedScenario = scenario
                } label: {
                    HStack {
                        Image(systemName: scenario.icon)
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        
                        Text(scenario.title)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                if scenario != WatchScenario.allCases.last {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Last Session
    
    private func lastSessionSection(score: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Session")
                .font(.headline)
            
            HStack {
                Text("\(score)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor(score))
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
}

// MARK: - Watch Scenario

enum WatchScenario: String, CaseIterable, Identifiable {
    case boundary = "boundary"
    case sayNo = "sayno"
    case feedback = "feedback"
    case raise = "raise"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .boundary: return "Set Boundary"
        case .sayNo: return "Say No"
        case .feedback: return "Give Feedback"
        case .raise: return "Ask for Raise"
        }
    }
    
    var icon: String {
        switch self {
        case .boundary: return "hand.raised.fill"
        case .sayNo: return "xmark.circle.fill"
        case .feedback: return "text.bubble.fill"
        case .raise: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var prompt: String {
        switch self {
        case .boundary: return "Practice setting a clear boundary."
        case .sayNo: return "Practice declining a request."
        case .feedback: return "Practice giving constructive feedback."
        case .raise: return "Practice asking for what you deserve."
        }
    }
}

// MARK: - Preview

#Preview {
    WatchHomeView()
}
