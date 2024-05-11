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
                    .frame(maxWidth: .infinity)
                Spacer()
                OrderView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading, content: {
                Button("Exit POS") {
                    // TODO
                }
            })
            ToolbarItem(placement: .principal, content: {
                Button("Reader not connected") {
                    // TODO
                }
            })
            ToolbarItem(placement: .primaryAction, content: {
                Button("History") {
                    // TODO
                }
            })
        }
    }
}
