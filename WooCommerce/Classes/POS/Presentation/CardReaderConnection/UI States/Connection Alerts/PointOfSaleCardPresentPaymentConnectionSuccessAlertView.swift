import SwiftUI

struct PointOfSaleCardPresentPaymentConnectionSuccessAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Image(decorative: viewModel.imageName)

            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
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
