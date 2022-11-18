import SwiftUI
import Yosemite

struct AnalyticsHub: View {
    @ObservedObject private var viewModel: AnalyticsHubViewModel

    init(_ viewModel: AnalyticsHubViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct AnalyticsHub_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AnalyticsHubViewModel(selectedTimeRange: .thisYear)
        AnalyticsHub(viewModel)
    }
}
