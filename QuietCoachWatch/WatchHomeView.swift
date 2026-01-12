// WatchHomeView.swift
// QuietCoachWatch
//
// Main watch interface. Quick scenarios and a fast start.

import SwiftUI

struct WatchHomeView: View {
    
    // MARK: - State
    
    @State private var selectedScenario: WatchScenario?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick practice scenarios
                    scenarioSection
                }
                .padding(.horizontal)
            }
            .navigationTitle("Quiet Coach")
            .sheet(item: $selectedScenario) { scenario in
                WatchRehearseView(scenario: scenario)
            }
        }
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
