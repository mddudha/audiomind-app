//
//  AudioMindWidget.swift
//  AudioMindWidget
//
//  Created by Mirvaben Dudhagara on 7/6/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct AudioMindWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            WidgetContentView(text: "Tap to record")
        case .systemMedium:
            WidgetContentView(text: "Tap to start recording audio notes")
        case .systemLarge:
            WidgetContentView(text: "Tap to start recording audio notes")
        default:
            WidgetContentView(text: "Tap to record")
        }
    }
}

struct WidgetContentView: View {
    let text: String

    var body: some View {
        ZStack {
            Color("MossGreen")
            VStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                Text(text)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct AudioMindWidget: Widget {
    let kind: String = "AudioMindWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AudioMindWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color("MossGreen")
                }
        }
        .configurationDisplayName("AudioMind Quick Notes")
        .description("Tap to quickly start taking audio notes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    AudioMindWidget()
} timeline: {
    SimpleEntry(date: .now)
}

import SwiftUI

struct FlatWaveformView: View {
    var color: Color = Color("DarkGreen")
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let midY = geometry.size.height / 2
                path.move(to: CGPoint(x: 0, y: midY))
                path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
            }
            .stroke(color.opacity(0.7), lineWidth: 4)
        }
        .frame(height: 24)
        .padding(.horizontal, 8)
    }
}
