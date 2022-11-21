import SwiftUI
import Yosemite

final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {
    init(timeRange: StatsTimeRangeV4) {
        super.init(rootView: AnalyticsHubView(timeRange: timeRange))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct AnalyticsHubView: View {
    let timeRange: StatsTimeRangeV4

    var body: some View {
        Text("Selected time range: \(timeRange.rawValue)")
    }
}
