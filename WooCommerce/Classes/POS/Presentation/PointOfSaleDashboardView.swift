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
                Button("History") {
                    debugPrint("Not implemented")
                }
            })
        }
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            NavigationView {
                CardReaderSettingsFlowPresentingView(
                    configuration: viewModel.dependencies.cardPresentPaymentsConfiguration,
                    siteID: viewModel.dependencies.siteID)
                .navigationBarItems(leading: Button(Localization.done, action: {
                    viewModel.showsCardReaderSheet = false
                }))
            }
        })
    }
}

private extension PointOfSaleDashboardView {
    enum Localization {
        static let done = NSLocalizedString(
            "pos.cardReaderConnection.navigation.done.button.title",
            value: "Done",
            comment: "Title for a done button in the navigation bar in POS card reader connection flow.")
    }
}

#Preview {
    PointOfSaleDashboardView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                                                      dependencies: .init(siteID: 1,
                                                                                          cardPresentPaymentsConfiguration: .init(country: .US))))
}
