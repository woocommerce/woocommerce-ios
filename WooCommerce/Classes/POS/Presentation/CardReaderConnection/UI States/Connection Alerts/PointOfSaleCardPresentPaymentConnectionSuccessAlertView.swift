import SwiftUI

struct PointOfSaleCardPresentPaymentConnectionSuccessAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            Image(viewModel.imageName)

            Button(viewModel.buttonViewModel.title,
                   action: viewModel.buttonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectionSuccessAlertView(
        viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(doneAction: {}))
}
