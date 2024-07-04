import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentCaptureErrorMessageView: View {
    @StateObject private var viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel

    init(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        HStack {
            VStack {
                Text(viewModel.title)
                Text(viewModel.message)
            }

            Button(viewModel.moreInfoButtonViewModel.title,
                   action: viewModel.moreInfoButtonViewModel.actionHandler)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
        }
        .sheet(isPresented: $viewModel.showsInfoSheet) {
            PointOfSaleCardPresentPaymentCaptureFailedView()
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentCaptureErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(
            cancelButtonAction: {}))
}
