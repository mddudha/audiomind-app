//
//  AudioMindWidgetLiveActivity.swift
//  AudioMindWidget
//
//  Created by Mirvaben Dudhagara on 7/6/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AudioMindWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AudioMindWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AudioMindWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension AudioMindWidgetAttributes {
    fileprivate static var preview: AudioMindWidgetAttributes {
        AudioMindWidgetAttributes(name: "World")
    }
}

extension AudioMindWidgetAttributes.ContentState {
    fileprivate static var smiley: AudioMindWidgetAttributes.ContentState {
        AudioMindWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AudioMindWidgetAttributes.ContentState {
         AudioMindWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AudioMindWidgetAttributes.preview) {
   AudioMindWidgetLiveActivity()
} contentStates: {
    AudioMindWidgetAttributes.ContentState.smiley
    AudioMindWidgetAttributes.ContentState.starEyes
}
