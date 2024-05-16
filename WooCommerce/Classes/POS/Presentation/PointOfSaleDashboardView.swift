import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var historyViewModel: PointOfSaleHistoryViewModel

    @State private var showHistory: Bool = false

    init(viewModel: PointOfSaleDashboardViewModel, historyViewModel: PointOfSaleHistoryViewModel) {
        self.viewModel = viewModel
        self.historyViewModel = historyViewModel
    }

    var body: some View {
        VStack {
            Text("WooCommerce Point Of Sale")
                .foregroundColor(Color.white)
            HStack {
                ProductGridView(viewModel: viewModel)
                    .background(Color.secondaryBackground)
                    .frame(maxWidth: .infinity)
                Spacer()
                CartView(viewModel: viewModel)
                    .background(Color.secondaryBackground)
                    .frame(maxWidth: .infinity)
            }
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
                Button(historyViewModel.items.isEmpty ? "History" : "History (\(historyViewModel.items.count))") {
                    showHistory = true
                }
            })
        }
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            CardReaderConnectionView(viewModel: viewModel.cardReaderConnectionViewModel)
        })
        .sheet(isPresented: $showHistory) {
            PointOfSaleHistoryView(viewModel: historyViewModel)
        }
    }
}

#Preview {
    PointOfSaleDashboardView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader)),
                             historyViewModel: PointOfSaleHistoryViewModel(items: []))
}
