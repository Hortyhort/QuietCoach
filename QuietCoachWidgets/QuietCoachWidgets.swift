// QuietCoachWidgets.swift
// QuietCoachWidgets
//
// Widget bundle for Quiet Coach. Includes last session
// summary, quick practice, and recording controls.

import WidgetKit
import SwiftUI

@main
struct QuietCoachWidgets: WidgetBundle {
    var body: some Widget {
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
