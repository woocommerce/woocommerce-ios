import SwiftUI

struct CardPresentPaymentConnectingToReaderView: View {
    private let viewModel: CardPresentPaymentConnectingToReaderAlertViewModel

    init(viewModel: CardPresentPaymentConnectingToReaderAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)
            
            viewModel.image
            
            Text(viewModel.instruction)
        }
    }
}

#Preview {
    CardPresentPaymentConnectingToReaderView(viewModel: CardPresentPaymentConnectingToReaderAlertViewModel())
}
