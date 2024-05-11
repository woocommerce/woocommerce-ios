import SwiftUI

struct OrderView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Product XYZ")
            Text("Product XYZ")
            Text("Product XYZ")
            Text("Product XYZ")
            Text("Product XYZ")
            Text("Product XYZ")
            Button("Pay now") {
                viewModel.callbackFromOrder()
            }
        }
    }
}
