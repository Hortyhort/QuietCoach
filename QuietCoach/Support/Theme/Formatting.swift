// Formatting.swift
// QuietCoach
//
// Time and date formatting extensions.

import Foundation

// MARK: - Time Formatting

extension TimeInterval {
    /// Format as MM:SS for display
    var qcFormattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Date Formatting

extension Date {
    /// Short date format: "Jan 15"
    var qcShortString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Medium date format: "January 15, 2024"
    var qcMediumString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Relative time: "Today", "Yesterday", "3 days ago"
    var qcRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
