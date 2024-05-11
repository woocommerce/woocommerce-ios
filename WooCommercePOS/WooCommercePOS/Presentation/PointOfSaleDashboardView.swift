import SwiftUI

struct PointOfSaleDashboardView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("WooCommerce Point Of Sale")
            HStack {
                ProductGridView(viewModel: viewModel)
                OrderView(viewModel: viewModel)
            }
        }
    }
}
