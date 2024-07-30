import SwiftUI

struct PointOfSaleCardPresentPaymentFoundReadersView: View {
    let viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel

    var body: some View {
        VStack {
            Text(viewModel.title)

            Image(viewModel.imageName)

            Button(viewModel.connectButton.title,
                   action: viewModel.connectButton.actionHandler)
            .buttonStyle(PrimaryButtonStyle())

            Button(viewModel.continueSearchButton.title,
                   action: viewModel.continueSearchButton.actionHandler)
            .buttonStyle(SecondaryButtonStyle())

            Button(viewModel.cancelSearchButton.title,
                   action: viewModel.cancelSearchButton.actionHandler)
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentFoundReadersView(viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
        readerName: "READER NAME",
        connectAction: {},
        continueSearchAction: {},
        endSearchAction: {}))
}
