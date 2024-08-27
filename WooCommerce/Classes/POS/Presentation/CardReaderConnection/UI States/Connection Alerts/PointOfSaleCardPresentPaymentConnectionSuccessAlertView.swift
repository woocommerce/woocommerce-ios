import SwiftUI

struct PointOfSaleCardPresentPaymentConnectionSuccessAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)
        }
        .posModalCloseButton(action: viewModel.buttonViewModel.actionHandler)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectionSuccessAlertView(
        viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(doneAction: {}))
}
