import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("WooCommerce Point Of Sale")
                .foregroundColor(Color.white)
            HStack {
                switch viewModel.orderStage {
                case .building:
                    productGridView
                    Spacer()
                    cartView
                case .finalizing:
                    cartView
                    Spacer()
                    totalsView
                }
            }
            .padding()
        }
        .background(Color.primaryBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading, content: {
                Button("Exit POS") {
                    presentationMode.wrappedValue.dismiss()
                }
            })
            ToolbarItem(placement: .principal, content: {
                Button("Reader not connected") {
                    viewModel.showCardReaderConnection()
                }
            })
            ToolbarItem(placement: .primaryAction, content: {
                Button("History") {
                    debugPrint("Not implemented")
                }
            })
        }
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            CardReaderConnectionView(viewModel: viewModel.cardReaderConnectionViewModel)
        })
        .sheet(isPresented: $viewModel.showsFilterSheet, content: {
            FilterView(viewModel: viewModel)
        })
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var cartView: some View {
        CartView(viewModel: viewModel)
            .background(Color.secondaryBackground)
            .frame(maxWidth: .infinity)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel)
            .background(Color.secondaryBackground)
            .frame(maxWidth: .infinity)
    }

    var productGridView: some View {
        ProductGridView(viewModel: viewModel)
            .background(Color.secondaryBackground)
            .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    PointOfSaleDashboardView(viewModel: PointOfSaleDashboardViewModel(products: POSProductProvider.provideProductsForPreview(),
                                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                                                      currencySettings: .init()))
}
#endif
