// QuietCoachWidgets.swift
// QuietCoachWidgets
//
// Widget bundle for Quiet Coach. Includes streak tracking,
// last session summary, and quick practice launch.

import WidgetKit
import SwiftUI

@main
struct QuietCoachWidgets: WidgetBundle {
    var body: some Widget {
        PracticeStreakWidget()
        LastSessionWidget()
        QuickPracticeWidget()
        #if os(iOS)
        RehearsalLiveActivity()
        if #available(iOS 18.0, *) {
            QuickRecordControl()
        }
        #endif
    }
}
