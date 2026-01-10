// PerformanceMonitor.swift
// QuietCoach
//
// Performance monitoring for critical operations.
// Tracks timing, memory, and identifies bottlenecks.

import Foundation
import OSLog
import QuartzCore
import SwiftUI
import Combine

// MARK: - Performance Span

/// A span representing a timed operation
final class PerformanceSpan: @unchecked Sendable {
    let name: String
    let category: PerformanceCategory
    let startTime: CFAbsoluteTime
    private(set) var endTime: CFAbsoluteTime?
    private(set) var metadata: [String: String] = [:]

    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime - startTime
    }

    var isComplete: Bool {
        endTime != nil
    }

    init(name: String, category: PerformanceCategory) {
        self.name = name
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
    }

    func addMetadata(_ key: String, value: String) {
        metadata[key] = value
    }

    func finish() {
        guard endTime == nil else { return }
        endTime = CFAbsoluteTimeGetCurrent()
    }
}

// MARK: - Performance Category

enum PerformanceCategory: String, Sendable {
    case recording = "recording"
    case analysis = "analysis"
    case transcription = "transcription"
    case storage = "storage"
    case ui = "ui"
    case network = "network"
}

// MARK: - Performance Monitor

@MainActor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private let logger = Logger(subsystem: "com.quietcoach", category: "Performance")
    private var activeSpans: [String: PerformanceSpan] = [:]
    private var completedSpans: [PerformanceSpan] = []
    private let maxCompletedSpans = 100

    private(set) var isEnabled = true

    // Memory pressure handling
    private var memoryWarningCancellable: AnyCancellable?
    private var memoryPressureHandlers: [() -> Void] = []

    private init() {
        setupMemoryWarningObserver()
    }

    // MARK: - Memory Pressure Handling

    private func setupMemoryWarningObserver() {
        #if os(iOS)
        memoryWarningCancellable = NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
        #endif
    }

    private func handleMemoryWarning() {
        logger.warning("Memory warning received - triggering cleanup")
        logMemoryState("Before cleanup")

        // Clear completed spans
        completedSpans.removeAll()

        // Notify registered handlers
        for handler in memoryPressureHandlers {
            handler()
        }

        logMemoryState("After cleanup")
    }

    /// Register a handler to be called on memory pressure
    func registerMemoryPressureHandler(_ handler: @escaping () -> Void) {
        memoryPressureHandlers.append(handler)
    }

    // MARK: - Configuration

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Span Management

    /// Start a new performance span
    @discardableResult
    func startSpan(_ name: String, category: PerformanceCategory) -> PerformanceSpan {
        let span = PerformanceSpan(name: name, category: category)

        if isEnabled {
            activeSpans[name] = span
            logger.debug("Started span: \(name)")
        }

        return span
    }

    /// End a performance span by name
    func endSpan(_ name: String, metadata: [String: String] = [:]) {
        guard isEnabled else { return }

        guard let span = activeSpans.removeValue(forKey: name) else {
            logger.warning("Tried to end unknown span: \(name)")
            return
        }

        for (key, value) in metadata {
            span.addMetadata(key, value: value)
        }

        span.finish()

        // Store completed span
        completedSpans.append(span)
        if completedSpans.count > maxCompletedSpans {
            completedSpans.removeFirst()
        }

        // Log performance
        if let duration = span.duration {
            let durationMs = duration * 1000
            if durationMs > 1000 {
                logger.warning("Slow operation: \(name) took \(String(format: "%.0f", durationMs))ms")
            } else {
                logger.debug("Completed span: \(name) in \(String(format: "%.0f", durationMs))ms")
            }

            // Track in analytics if significant
            if durationMs > 100 {
                trackPerformanceMetric(span)
            }
        }
    }

    /// Measure a synchronous operation
    func measure<T>(_ name: String, category: PerformanceCategory, operation: () throws -> T) rethrows -> T {
        _ = startSpan(name, category: category)
        defer { endSpan(name) }
        return try operation()
    }

    /// Measure an async operation
    func measureAsync<T>(_ name: String, category: PerformanceCategory, operation: () async throws -> T) async rethrows -> T {
        _ = startSpan(name, category: category)
        defer { endSpan(name) }
        return try await operation()
    }

    // MARK: - Memory Monitoring

    /// Get current memory usage
    var currentMemoryUsage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? info.resident_size : 0
    }

    /// Get memory usage in MB
    var memoryUsageMB: Double {
        Double(currentMemoryUsage) / 1024 / 1024
    }

    /// Log current memory state
    func logMemoryState(_ context: String) {
        guard isEnabled else { return }
        logger.debug("[\(context)] Memory: \(String(format: "%.1f", self.memoryUsageMB))MB")
    }

    // MARK: - Analytics Integration

    private func trackPerformanceMetric(_ span: PerformanceSpan) {
        guard let duration = span.duration else { return }

        // Bucket the duration
        let bucket: String
        let durationMs = duration * 1000
        switch durationMs {
        case 0..<100: bucket = "0-100ms"
        case 100..<500: bucket = "100-500ms"
        case 500..<1000: bucket = "500ms-1s"
        case 1000..<3000: bucket = "1-3s"
        default: bucket = "3s+"
        }

        // Track via crash reporting breadcrumb
        CrashReporting.shared.recordBreadcrumb(
            "Performance: \(span.name)",
            category: .stateChange,
            data: [
                "duration_bucket": bucket,
                "category": span.category.rawValue
            ]
        )
    }

    // MARK: - Reports

    /// Get performance summary
    var performanceSummary: PerformanceSummary {
        let spansByCategory = Dictionary(grouping: completedSpans) { $0.category }

        var categoryStats: [PerformanceCategory: CategoryStats] = [:]

        for (category, spans) in spansByCategory {
            let durations = spans.compactMap { $0.duration }
            guard !durations.isEmpty else { continue }

            let avg = durations.reduce(0, +) / Double(durations.count)
            let max = durations.max() ?? 0
            let min = durations.min() ?? 0

            categoryStats[category] = CategoryStats(
                count: spans.count,
                averageMs: avg * 1000,
                maxMs: max * 1000,
                minMs: min * 1000
            )
        }

        return PerformanceSummary(
            totalSpans: completedSpans.count,
            categoryStats: categoryStats,
            memoryMB: memoryUsageMB
        )
    }

    /// Clear completed spans
    func clearHistory() {
        completedSpans.removeAll()
    }
}

// MARK: - Performance Summary

struct PerformanceSummary {
    let totalSpans: Int
    let categoryStats: [PerformanceCategory: CategoryStats]
    let memoryMB: Double
}

struct CategoryStats {
    let count: Int
    let averageMs: Double
    let maxMs: Double
    let minMs: Double
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// Track recording session performance
    func trackRecordingStart() {
        startSpan("recording_session", category: .recording)
        logMemoryState("Recording Start")
    }

    func trackRecordingEnd(durationSeconds: Int) {
        endSpan("recording_session", metadata: ["duration": "\(durationSeconds)s"])
        logMemoryState("Recording End")
    }

    /// Track analysis performance
    func trackAnalysisStart() {
        startSpan("speech_analysis", category: .analysis)
    }

    func trackAnalysisEnd(wordCount: Int) {
        endSpan("speech_analysis", metadata: ["words": "\(wordCount)"])
    }

    /// Track transcription performance
    func trackTranscriptionStart() {
        startSpan("transcription", category: .transcription)
    }

    func trackTranscriptionEnd() {
        endSpan("transcription")
    }
}

// MARK: - UI Performance Tracking

extension View {
    /// Track view appearance performance
    func trackPerformance(_ name: String) -> some View {
        modifier(PerformanceTrackingModifier(viewName: name))
    }
}

private struct PerformanceTrackingModifier: ViewModifier {
    let viewName: String
    @State private var appearTime: CFAbsoluteTime?

    func body(content: Content) -> some View {
        content
            .onAppear {
                appearTime = CFAbsoluteTimeGetCurrent()
                Task { @MainActor in
                    _ = PerformanceMonitor.shared.startSpan("\(viewName)_render", category: .ui)
                }
            }
            .task {
                // End span after first frame is rendered
                try? await Task.sleep(for: .milliseconds(16))
                await MainActor.run {
                    if let start = appearTime {
                        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
                        PerformanceMonitor.shared.endSpan("\(viewName)_render", metadata: ["duration_ms": String(format: "%.1f", duration)])
                    }
                }
            }
    }
}

// MARK: - Debug View

#if DEBUG

struct PerformanceDebugView: View {
    @State private var summary: PerformanceSummary?
    @State private var refreshTrigger = false

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text(String(format: "%.1f MB", summary?.memoryMB ?? 0))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Tracked Operations")
                    Spacer()
                    Text("\(summary?.totalSpans ?? 0)")
                        .foregroundStyle(.secondary)
                }
            }

            if let stats = summary?.categoryStats, !stats.isEmpty {
                Section("By Category") {
                    ForEach(Array(stats.keys), id: \.self) { category in
                        if let stat = stats[category] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.rawValue.capitalized)
                                    .font(.headline)
                                HStack {
                                    Text("Avg: \(String(format: "%.0f", stat.averageMs))ms")
                                    Text("Max: \(String(format: "%.0f", stat.maxMs))ms")
                                    Text("Count: \(stat.count)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Performance")
        .task {
            await loadSummary()
        }
        .refreshable {
            await loadSummary()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") {
                    Task { @MainActor in
                        PerformanceMonitor.shared.clearHistory()
                        await loadSummary()
                    }
                }
            }
        }
    }

    @MainActor
    private func loadSummary() async {
        summary = PerformanceMonitor.shared.performanceSummary
    }
}
#endif
