import SwiftUI

struct CardPresentPaymentFoundReadersView: View {
    let viewModel: CardPresentPaymentFoundReaderAlertViewModel

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

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
    CardPresentPaymentFoundReadersView(viewModel: CardPresentPaymentFoundReaderAlertViewModel(
        readerName: "READER NAME",
        connectAction: {},
        continueSearchAction: {},
        endSearchAction: {}))
}
