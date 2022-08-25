import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct StoreWidgetsEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

@main
struct StoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StoreWidgets()
        StoreInfoWidget()
    }
}


struct StoreWidgets: Widget {
    let kind: String = "StoreWidgets"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            StoreWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}


struct StoreInfoEntry: TimelineEntry {
    var date: Date
    var range: String
    var name: String
    var revenue: String
    var visitors: String
    var orders: String
    var conversion: String
}

struct StoreInfoProvider: TimelineProvider {
    func placeholder(in context: Context) -> StoreInfoEntry {
        StoreInfoEntry(date: .now,
                       range: "Today",
                       name: "Ernest Shop",
                       revenue: "$132.234",
                       visitors: "67",
                       orders: "23",
                       conversion: "37%")
    }

    func getSnapshot(in context: Context, completion: @escaping (StoreInfoEntry) -> Void) {
        completion(StoreInfoEntry(date: .now,
                                  range: "Today",
                                  name: "Ernest Shop",
                                  revenue: "$132.234",
                                  visitors: "67",
                                  orders: "23",
                                  conversion: "37%"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StoreInfoEntry>) -> Void) {
        print("Get Timeline called")
    }
}

struct StoreInfoView: View {
    let entry: StoreInfoEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(entry.name)
                Spacer()
                Text(entry.range)
            }

            HStack() {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue")
                    Text(entry.revenue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Visitors")
                    Text(entry.visitors)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Orders")
                    Text(entry.orders)

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Conversion")
                    Text(entry.conversion)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }
        }
        .padding(.horizontal, 16)
    }
}

struct StoreInfoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StoreInfoWidget", provider: StoreInfoProvider()) { entry in
            StoreInfoView(entry: entry)
        }
        .configurationDisplayName("Store Info")
        .supportedFamilies([.systemMedium])
    }
}

struct StoreWidgets_Previews: PreviewProvider {
    static var previews: some View {
        StoreWidgetsEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        StoreInfoView(
            entry: StoreInfoEntry(date: .now,
                                  range: "Today",
                                  name: "Ernest Shop",
                                  revenue: "$132.234",
                                  visitors: "67",
                                  orders: "23",
                                  conversion: "37%")
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
