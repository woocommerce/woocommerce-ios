import SwiftUI

/// View to enable WC Analytics for the current store
///
struct EnableAnalyticsView: View {
    @ObservedObject private var viewModel: EnableAnalyticsViewModel

    init(viewModel: EnableAnalyticsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct EnableAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        EnableAnalyticsView(viewModel: .init(siteID: 123))
    }
}
