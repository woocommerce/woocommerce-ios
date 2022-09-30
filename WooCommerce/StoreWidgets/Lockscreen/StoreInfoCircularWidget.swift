import SwiftUI
import WidgetKit

/// Entry point for StoreInfo Lock Screen Widget (circular type)
///
struct StoreInfoCircularWidget: View {
    // Entry to render
    let entry: StoreInfoEntry

    var body: some View {
        switch entry {
        case .data(let data):
            StoreInfoCircularView(entryData: data)
        case .notConnected, .error:
            UnableToFetchView()
        }
    }
}

private struct StoreInfoCircularView: View {
    // Stats data to render
    let entryData: StoreInfoData

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
            Text(entryData.revenueCompact)
        }
    }
}

private struct UnableToFetchView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
            Text("⚠")
                .font(.largeTitle)
        }
    }
}

// MARK: - Previews

@available(iOSApplicationExtension 16.0, *)
struct StoreInfoCircularWidget_Previews: PreviewProvider {
    static var exampleData = StoreInfoData(range: "Today",
                                           name: "Ernest Shop",
                                           revenue: "$132.234",
                                           revenueCompact: "$132",
                                           visitors: "67",
                                           orders: "23",
                                           conversion: "34%",
                                           updatedTime: "10:24 PM")

    static var previews: some View {
        StoreInfoCircularView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))

        UnableToFetchView()
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Unable to fetch")
    }
}
