// HistoryView.swift
// QuietCoach
//
// Full session history with filtering and search.
// Your journey, documented.

import SwiftUI

struct HistoryView: View {

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var sortOrder: SortOrder = .newest

    // MARK: - Filter Options

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case boundaries = "Boundaries"
        case career = "Career"
        case relationships = "Relationships"
        case difficult = "Difficult"

        var category: Scenario.Category? {
            switch self {
            case .all: return nil
            case .boundaries: return .boundaries
            case .career: return .career
            case .relationships: return .relationships
            case .difficult: return .difficult
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
    }

    // MARK: - Computed Properties

    private var filteredSessions: [RehearsalSession] {
        var sessions = repository.sessions

        // Apply category filter
        if let category = selectedFilter.category {
            sessions = sessions.filter { session in
                session.scenario?.category == category
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                session.scenario?.title.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply sort
        switch sortOrder {
        case .newest:
            sessions.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            sessions.sort { $0.createdAt < $1.createdAt }
        }

        return sessions
    }

    private var groupedSessions: [(String, [RehearsalSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session -> String in
            if calendar.isDateInToday(session.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(session.createdAt) {
                return "Yesterday"
            } else if calendar.isDate(session.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(session.createdAt, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: session.createdAt)
            }
        }

        // Sort groups by most recent first
        let sortedKeys = ["Today", "Yesterday", "This Week", "This Month"] +
            grouped.keys.filter { !["Today", "Yesterday", "This Week", "This Month"].contains($0) }.sorted().reversed()

        return sortedKeys.compactMap { key in
            guard let sessions = grouped[key], !sessions.isEmpty else { return nil }
            return (key, sessions)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if repository.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .background(Color.qcBackground)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                repository.fetchAllSessions()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.qcAccent)
                }
            }
            .searchable(text: $searchText, prompt: "Search scenarios")
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            // Filter chips
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            FilterChip(
                                title: option.rawValue,
                                isSelected: selectedFilter == option
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = option
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Sort picker
            Section {
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .tint(.qcAccent)
            }

            // Grouped sessions
            ForEach(groupedSessions, id: \.0) { group, sessions in
                Section(group) {
                    ForEach(sessions) { session in
                        NavigationLink(value: session) {
                            HistorySessionRow(session: session)
                        }
                        .listRowBackground(Color.qcSurface)
                    }
                    .onDelete { indexSet in
                        deleteSessions(at: indexSet, from: sessions)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: RehearsalSession.self) { session in
            ReviewView(
                session: session,
                onTryAgain: { dismiss() },
                onDone: { dismiss() }
            )
            .environment(repository)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(config: .noSessions) {
            // Navigate to home to start practicing
            dismiss()
        }
    }

    // MARK: - Actions

    private func deleteSessions(at indexSet: IndexSet, from sessions: [RehearsalSession]) {
        for index in indexSet {
            repository.deleteSession(sessions[index])
        }
    }
}

// MARK: - History Session Row

struct HistorySessionRow: View {
    let session: RehearsalSession

    var body: some View {
        HStack(spacing: 12) {
            // Scenario icon
            if let scenario = session.scenario {
                Image(systemName: scenario.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.qcAccent)
                    .frame(width: 32)
            }

            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.scenario?.title ?? "Unknown")
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)

                HStack(spacing: 8) {
                    Text(session.formattedDate)
                    Text("•")
                    Text(session.formattedDuration)
                }
                .font(.qcCaption)
                .foregroundColor(.qcTextTertiary)

                if let highlight = sessionHighlight {
                    Text(highlight)
                        .font(.qcCaption)
                        .foregroundColor(.qcTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var sessionHighlight: String? {
        if let focus = session.tryAgainFocus?.goal {
            return "Next: \(focus)"
        }
        if let winNote = session.coachNotes.first(where: { $0.title == "What worked" }) {
            return winNote.body
        }
        return session.coachNotes.first?.body
    }

    private var accessibilitySummary: String {
        var summary = "\(session.scenario?.title ?? "Session"). \(session.formattedDate). Duration \(session.formattedDuration)."
        if let highlight = sessionHighlight {
            summary += " \(highlight)"
        }
        return summary
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.qcSubheadline)
                .foregroundColor(isSelected ? .black : .qcTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.qcAccent : Color.qcSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .environment(SessionRepository.placeholder)
}
