import WidgetKit
import KeychainAccess

/// Type that represents the Widget information
///
struct StoreInfoEntry: TimelineEntry {
    /// Date to request new info
    ///
    var date: Date

    /// Eg: Today, Weekly, Monthly, Yearly
    ///
    var range: String

    /// Store name
    ///
    var name: String

    /// Revenue at the range (eg: today)
    ///
    var revenue: String

    /// Visitors count at the range (eg: today)
    ///
    var visitors: String

    /// Order count at the range (eg: today)
    ///
    var orders: String

    /// Conversion at the range (eg: today)
    ///
    var conversion: String
}

/// Type that provides data entries to the widget system.
///
struct StoreInfoProvider: TimelineProvider {
    /// Redacted entry with sample data.
    ///
    func placeholder(in context: Context) -> StoreInfoEntry {
        StoreInfoEntry(date: Date(),
                       range: "Today",
                       name: "Ernest Shop",
                       revenue: "$132.234",
                       visitors: "67",
                       orders: "23",
                       conversion: "37%")
    }

    /// Quick Snapshot. Required when previewing the widget.
    /// TODO: Update with real data.
    ///
    func getSnapshot(in context: Context, completion: @escaping (StoreInfoEntry) -> Void) {
        completion(StoreInfoEntry(date: Date(),
                                  range: "Today",
                                  name: "Ernest Shop",
                                  revenue: "$132.234",
                                  visitors: "67",
                                  orders: "23",
                                  conversion: "37%"))
    }

    /// Real data widget.
    /// TODO: Update with real data.
    ///
    func getTimeline(in context: Context, completion: @escaping (Timeline<StoreInfoEntry>) -> Void) {
        let entry = StoreInfoEntry(date: Date(),
                                   range: "Today",
                                   name: "Ernest Shop",
                                   revenue: "$132.234",
                                   visitors: "67",
                                   orders: "23",
                                   conversion: "37%")
        let timeline = Timeline<StoreInfoEntry>(entries: [entry], policy: .never)
        completion(timeline)
    }
}
