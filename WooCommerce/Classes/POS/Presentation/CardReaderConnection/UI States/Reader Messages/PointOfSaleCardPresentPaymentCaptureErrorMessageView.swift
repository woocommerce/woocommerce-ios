import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentCaptureErrorMessageView: View {
    @StateObject private var viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel

    init(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorXMark()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.primaryText)
                    .font(.posTitle)

                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                    Text(viewModel.message)
                    Text(viewModel.nextStep)
                }
                .font(.posBody)
                .foregroundStyle(Color.primaryText)
            }

            VStack(spacing: PointOfSaleCardPresentPaymentLayout.buttonSpacing) {
                Button(viewModel.tryAgainButtonViewModel.title,
                       action: viewModel.tryAgainButtonViewModel.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())

                Button(action: viewModel.newOrderButtonViewModel.actionHandler) {
                    Label(viewModel.newOrderButtonViewModel.title, systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(POSSecondaryButtonStyle())
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: PointOfSaleCardPresentPaymentLayout.errorContentMaxWidth)
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
            tryAgainButtonAction: {},
            newOrderButtonAction: {}))
}
