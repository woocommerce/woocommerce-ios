import SwiftUI

struct FilterView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button("Filter") {
            // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12761
        }
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title2)
        .foregroundColor(Color.white)
        .background(Color.secondaryBackground)
        .cornerRadius(10)
        .border(Color.white, width: 2)
    }
}
