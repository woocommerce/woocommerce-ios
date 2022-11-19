import SwiftUI
import Yosemite

final class AnalyticsHubHostingViewController: UIHostingController<AnalyticsHubView> {
    init(viewModel: AnalyticsHubViewModel) {
        super.init(rootView: AnalyticsHubView(viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct AnalyticsHubView: View {
    @ObservedObject private var viewModel: AnalyticsHubViewModel

    init(_ viewModel: AnalyticsHubViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let timeRange = AnalyticsHubTimeRange(selectionType: .today)
        Text("Selected time range: \(viewModel.selectedTimeRange.rawValue)")
        Text("Start date: \(timeRange.timeRange.start.description)")
        Text("End date: \(timeRange.timeRange.end.description)")
    }
}
