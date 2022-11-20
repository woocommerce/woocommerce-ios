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
        Text("Selected Start date: \(viewModel.analyticsTimeRange.selectedTimeRange.start.description)")
        Text("Selected End date: \(viewModel.analyticsTimeRange.selectedTimeRange.end.description)")
        Spacer()
        Text("Previous Start date: \(viewModel.analyticsTimeRange.previousTimeRange.start.description)")
        Text("Previous End date: \(viewModel.analyticsTimeRange.previousTimeRange.start.description)")
    }
}
