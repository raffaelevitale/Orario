//
//  ScheduleWidgetLiveActivity.swift
//  ScheduleWidget
//
//  Created by Raffaele Vitale on 25/09/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ScheduleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentLesson: String
        var teacher: String
        var classroom: String
        var startTime: String
        var endTime: String
        var progress: Double // 0.0 - 1.0
        var remainingMinutes: Int
        var color: String
    }

    // Fixed non-changing properties about your activity go here!
    var lessonTitle: String
    var totalDuration: Int // durata totale in minuti
}

struct ScheduleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScheduleWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("📚 \(context.state.currentLesson)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Prof. \(context.state.teacher)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.remainingMinutes) min")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: context.state.color))
                        Text("rimanenti")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.classroom)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: context.state.color)))
                            .scaleEffect(x: 1, y: 0.8)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.startTime)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(context.state.progress * 100))% completato")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(context.state.endTime)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Text("📚")
                    .font(.caption)
            } compactTrailing: {
                Text("\(context.state.remainingMinutes)'")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: context.state.color))
            } minimal: {
                Text("\(context.state.remainingMinutes)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: context.state.color))
            }
            .widgetURL(URL(string: "vallauri://schedule"))
            .keylineTint(Color(hex: context.state.color))
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<ScheduleWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header con info lezione
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📚 \(context.state.currentLesson)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        Text("Prof. \(context.state.teacher)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(context.state.classroom)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.remainingMinutes)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: context.state.color))
                    
                    Text("minuti rimanenti")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar
            VStack(spacing: 6) {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: context.state.color)))
                    .scaleEffect(x: 1, y: 1.5)
                
                HStack {
                    Text(context.state.startTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(context.state.progress * 100))% completato")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: context.state.color))
                    
                    Spacer()
                    
                    Text(context.state.endTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .activityBackgroundTint(Color(hex: context.state.color).opacity(0.1))
        .activitySystemActionForegroundColor(Color(hex: context.state.color))
    }
}

extension ScheduleWidgetAttributes {
    fileprivate static var preview: ScheduleWidgetAttributes {
        ScheduleWidgetAttributes(lessonTitle: "Matematica", totalDuration: 55)
    }
}

extension ScheduleWidgetAttributes.ContentState {
    fileprivate static var matematica: ScheduleWidgetAttributes.ContentState {
        ScheduleWidgetAttributes.ContentState(
            currentLesson: "Matematica",
            teacher: "GARRO V.",
            classroom: "T64 (28)",
            startTime: "09:45",
            endTime: "10:40",
            progress: 0.6,
            remainingMinutes: 22,
            color: "#ef5350"
        )
    }
     
    fileprivate static var informatica: ScheduleWidgetAttributes.ContentState {
        ScheduleWidgetAttributes.ContentState(
            currentLesson: "Informatica",
            teacher: "BONAVIA M.",
            classroom: "LAB.119B EULERO",
            startTime: "07:50",
            endTime: "08:50",
            progress: 0.3,
            remainingMinutes: 42,
            color: "#7e57c2"
        )
    }
}

#Preview("Notification", as: .content, using: ScheduleWidgetAttributes.preview) {
   ScheduleWidgetLiveActivity()
} contentStates: {
    ScheduleWidgetAttributes.ContentState.matematica
    ScheduleWidgetAttributes.ContentState.informatica
}
