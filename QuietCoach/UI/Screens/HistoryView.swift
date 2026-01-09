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
    @State private var isCompareMode = false
    @State private var selectedForComparison: Set<UUID> = []
    @State private var showingComparison = false

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
        case highestScore = "Highest Score"
        case lowestScore = "Lowest Score"
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
        case .highestScore:
            sessions.sort { ($0.scores?.overall ?? 0) > ($1.scores?.overall ?? 0) }
        case .lowestScore:
            sessions.sort { ($0.scores?.overall ?? 0) < ($1.scores?.overall ?? 0) }
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !repository.sessions.isEmpty {
                        Button(isCompareMode ? "Cancel" : "Compare") {
                            withAnimation {
                                isCompareMode.toggle()
                                if !isCompareMode {
                                    selectedForComparison.removeAll()
                                }
                            }
                        }
                        .foregroundColor(isCompareMode ? .qcTextSecondary : .qcAccent)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isCompareMode && canCompare {
                        Button("Compare") {
                            showingComparison = true
                        }
                        .foregroundColor(.qcAccent)
                        .fontWeight(.semibold)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.qcAccent)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search scenarios")
            .sheet(isPresented: $showingComparison) {
                if sessionsForComparison.count == 2 {
                    SessionComparisonView(
                        sessionA: sessionsForComparison[0],
                        sessionB: sessionsForComparison[1]
                    )
                }
            }
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

            // Stats summary
            if !filteredSessions.isEmpty {
                Section {
                    statsRow
                }
            }

            // Compare mode hint
            if isCompareMode {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.qcAccent)
                        Text("Select 2 sessions to compare")
                            .font(.qcSubheadline)
                            .foregroundColor(.qcTextSecondary)
                        Spacer()
                        Text("\(selectedForComparison.count)/2")
                            .font(.qcCaption)
                            .foregroundColor(.qcAccent)
                    }
                }
            }

            // Grouped sessions
            ForEach(groupedSessions, id: \.0) { group, sessions in
                Section(group) {
                    ForEach(sessions) { session in
                        if isCompareMode {
                            CompareSelectableRow(
                                session: session,
                                isSelected: selectedForComparison.contains(session.id),
                                isDisabled: selectedForComparison.count >= 2 && !selectedForComparison.contains(session.id)
                            ) {
                                toggleSelection(session)
                            }
                            .listRowBackground(
                                selectedForComparison.contains(session.id)
                                    ? Color.qcAccent.opacity(0.15)
                                    : Color.qcSurface
                            )
                        } else {
                            NavigationLink(value: session) {
                                HistorySessionRow(session: session)
                            }
                            .listRowBackground(Color.qcSurface)
                        }
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

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 24) {
            statItem(
                value: "\(filteredSessions.count)",
                label: "Sessions"
            )

            if let avgScore = averageScore {
                statItem(
                    value: "\(avgScore)",
                    label: "Avg Score"
                )
            }

            if let bestScore = bestScore {
                statItem(
                    value: "\(bestScore)",
                    label: "Best"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.qcTitle2)
                .foregroundColor(.qcAccent)

            Text(label)
                .font(.qcCaption)
                .foregroundColor(.qcTextSecondary)
        }
    }

    private var averageScore: Int? {
        let scores = filteredSessions.compactMap { $0.scores?.overall }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / scores.count
    }

    private var bestScore: Int? {
        filteredSessions.compactMap { $0.scores?.overall }.max()
    }

    private var sessionsForComparison: [RehearsalSession] {
        filteredSessions.filter { selectedForComparison.contains($0.id) }
    }

    private var canCompare: Bool {
        sessionsForComparison.count == 2
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.qcTextTertiary)

            Text("No sessions yet")
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            Text("Your rehearsal history will appear here")
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func deleteSessions(at indexSet: IndexSet, from sessions: [RehearsalSession]) {
        for index in indexSet {
            repository.deleteSession(sessions[index])
        }
    }

    private func toggleSelection(_ session: RehearsalSession) {
        if selectedForComparison.contains(session.id) {
            selectedForComparison.remove(session.id)
        } else if selectedForComparison.count < 2 {
            selectedForComparison.insert(session.id)
        }
    }
}

// MARK: - Compare Selectable Row

struct CompareSelectableRow: View {
    let session: RehearsalSession
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.qcAccent : Color.qcTextTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.qcAccent)
                            .frame(width: 16, height: 16)
                    }
                }

                // Session info
                HistorySessionRow(session: session)
            }
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.4 : 1.0)
        .disabled(isDisabled)
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
            }

            Spacer()

            // Score badge
            if let scores = session.scores {
                ScoreBadge(score: scores.overall)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.scenario?.title ?? "Session"). \(session.formattedDate). Score: \(session.scores?.overall ?? 0)")
    }
}

// MARK: - Score Badge

struct ScoreBadge: View {
    let score: Int

    private var color: Color {
        switch score {
        case 85...100: return .qcMoodCelebration
        case 70..<85: return .qcMoodSuccess
        case 50..<70: return .qcMoodReady
        default: return .qcMoodEngaged
        }
    }

    var body: some View {
        Text("\(score)")
            .font(.qcScoreSmall)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
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
