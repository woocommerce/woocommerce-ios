import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    @ObservedObject var testPaymentViewModel: PointOfSalePaymentsTestViewModel

    init(viewModel: PointOfSaleDashboardViewModel,
         testPaymentViewModel: PointOfSalePaymentsTestViewModel) {
        self.viewModel = viewModel
        self.testPaymentViewModel = testPaymentViewModel
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
            ToolbarItem(placement: .secondaryAction) {
                Button("Start Test Payment") {
                    Task {
                        await testPaymentViewModel.startTestPayment()
                    }
                }
            }
            ToolbarItem(placement: .primaryAction, content: {
                Button("History") {
                    debugPrint("Not implemented")
                }
            })
        }
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            CardReaderConnectionView(viewModel: viewModel.cardReaderConnectionViewModel)
        })
        .sheet(item: $testPaymentViewModel.onboardingViewModels) { onboardingViewModel in
            NavigationStack {
                InPersonPaymentsView(viewModel: onboardingViewModel)
                    .navigationTitle(Text(""))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        Button(action: testPaymentViewModel.cancel) {
                            Text("Cancel")
                        }
                    }
            }
        }
        .modal(item: $testPaymentViewModel.paymentModalViewModel) { item in
            CardPresentPaymentsModalView(viewModel: item)
        }
    }
}

#Preview {
    PointOfSaleDashboardView(
        viewModel: PointOfSaleDashboardViewModel(
            products: POSProductFactory.makeFakeProducts(),
            cardReaderConnectionViewModel: .init(state: .connectingToReader)),
        testPaymentViewModel: PointOfSalePaymentsTestViewModel(siteID: 123)
    )
}
