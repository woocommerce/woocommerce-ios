import SwiftUI

struct TotalsView: View {
    var body: some View {
        VStack {
            Text("Totals")
                .font(.title)
                .foregroundColor(Color.white)
            Spacer()
            HStack {
                Button("Take payment") { debugPrint("Not implemented") }
                    .padding(.all, 10)
                    .frame(maxWidth: .infinity, idealHeight: 120)
                    .font(.title)
                    .foregroundColor(Color.white)
                    .border(.white, width: 2)
                Button("Cash") { debugPrint("Not implemented") }
                    .padding(.all, 10)
                    .frame(maxWidth: .infinity, idealHeight: 120)
                    .font(.title)
                    .foregroundColor(Color.primaryBackground)
                    .background(Color.white)
                Button("Card") { debugPrint("Not implemented") }
                    .padding(.all, 10)
                    .frame(maxWidth: .infinity, idealHeight: 120)
                    .font(.title)
                    .foregroundColor(Color.primaryBackground)
                    .background(Color.white)
            }
        }
    }
}

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
                    ProductGridView(viewModel: viewModel)
                        .background(Color.secondaryBackground)
                        .frame(maxWidth: .infinity)
                    Spacer()
                    CartView(viewModel: viewModel)
                        .background(Color.secondaryBackground)
                        .frame(maxWidth: .infinity)
                case .finalizing:
                    CartView(viewModel: viewModel)
                        .background(Color.secondaryBackground)
                        .frame(maxWidth: .infinity)
                    Spacer()
                    TotalsView()
                        .background(Color.secondaryBackground)
                        .frame(maxWidth: .infinity)
                }
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

#if DEBUG
#Preview {
    PointOfSaleDashboardView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader)))
}
#endif
