import WidgetKit
import SwiftUI
import ReminderKit

/// Watch-face complication: shows the project currently at the top of the rotation (the head).
/// Reads the lightweight App-Group snapshot the watch app keeps up to date (`SharedHeadState`).
@main
struct ProjectReminderComplicationBundle: WidgetBundle {
    var body: some Widget {
        HeadProjectComplication()
    }
}

struct HeadEntry: TimelineEntry {
    let date: Date
    let title: String
}

struct HeadProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeadEntry {
        HeadEntry(date: Date(), title: "Project")
    }
    func getSnapshot(in context: Context, completion: @escaping (HeadEntry) -> Void) {
        completion(HeadEntry(date: Date(), title: SharedHeadState.read() ?? "No projects"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HeadEntry>) -> Void) {
        let entry = HeadEntry(date: Date(), title: SharedHeadState.read() ?? "No projects")
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct HeadProjectComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HeadProjectComplication", provider: HeadProvider()) { entry in
            HeadComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Current Project")
        .description("Shows the project at the top of your rotation.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct HeadComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HeadEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.title)
        case .accessoryCircular:
            ZStack {
                Circle().fill(.purple.opacity(0.25))
                Text(String(entry.title.first.map(Character.init) ?? "•").uppercased())
                    .font(.system(.title3, design: .rounded).bold())
            }
        default: // accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text("NOW").font(.caption2).foregroundStyle(.purple)
                Text(entry.title).font(.headline).lineLimit(2)
            }
        }
    }
}
