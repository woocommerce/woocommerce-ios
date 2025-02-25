import SwiftUI

struct PointOfSaleOrderSyncErrorMessageView: View {
    let viewModel: PointOfSaleOrderSyncErrorMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                Spacer()
                POSErrorExclamationMark(size: .large)
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)

                    Text(viewModel.message)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posBodyLargeRegular())
                        .padding([.leading, .trailing])
                }
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)
                Button(viewModel.actionModel.title, action: viewModel.actionModel.handler)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
                    .padding([.leading, .trailing], Constants.buttonSidePadding)
                    .padding([.bottom], Constants.buttonBottomPadding)
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleOrderSyncErrorMessageView {
    enum Constants {
        static let headerSpacing: CGFloat = POSSpacing.large
        static let textSpacing: CGFloat = POSSpacing.medium
        static let buttonSidePadding: CGFloat = POSPadding.xxLarge
        static let buttonBottomPadding: CGFloat = POSPadding.medium
    }
}

#Preview {
    PointOfSaleOrderSyncErrorMessageView(viewModel: PointOfSaleOrderSyncErrorMessageViewModel(message: "An error happened!",
                                                                                              handler: {}))
}
