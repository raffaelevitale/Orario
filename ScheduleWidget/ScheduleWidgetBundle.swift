//
//  ScheduleWidgetBundle.swift
//  ScheduleWidget
//
//  Created by Raffaele Vitale on 25/09/25.
//

import WidgetKit
import SwiftUI

@main
struct ScheduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScheduleWidget()
        CurrentLessonWidget()
        ScheduleWidgetControl()
        ScheduleWidgetLiveActivity()
    }
}
