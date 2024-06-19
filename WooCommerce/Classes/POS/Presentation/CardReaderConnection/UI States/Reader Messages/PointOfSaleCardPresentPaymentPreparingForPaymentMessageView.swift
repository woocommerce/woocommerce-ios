import SwiftUI

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel

    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(IndefiniteCircularProgressViewStyle(
                    size: Layout.progressViewSize,
                    lineWidth: Layout.progressViewLineWidth))

            Text(viewModel.message)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
        }
    }
}

private extension PointOfSaleCardPresentPaymentPreparingForPaymentMessageView {
    enum Layout {
        static let progressViewSize: CGFloat = 24
        static let progressViewLineWidth: CGFloat = 4
    }
}

#Preview {
    PointOfSaleCardPresentPaymentPreparingForPaymentMessageView(
        viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel(cancelAction: {}))
}
