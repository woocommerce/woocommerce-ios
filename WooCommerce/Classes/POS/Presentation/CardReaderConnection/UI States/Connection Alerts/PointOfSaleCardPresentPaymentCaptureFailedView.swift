import SwiftUI

struct PointOfSaleCardPresentPaymentCaptureFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentCaptureFailedAlertViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PointOfSaleCardPresentPaymentCaptureFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.errorDetails)

            Button(viewModel.cancelButtonTitle,
                   action: {
                dismiss()
            })
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentCaptureFailedView(
        viewModel: PointOfSaleCardPresentPaymentCaptureFailedAlertViewModel())
}
