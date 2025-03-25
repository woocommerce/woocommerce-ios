import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleOrderSyncCouponsErrorMessageView: View {
    let message: String
    let retryHandler: () -> Void

    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var attributedMessage: AttributedString {
        if let data = message.data(using: .utf8),
           let nsAttributedString = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.html],
               documentAttributes: nil) {
            var attributedString = AttributedString(nsAttributedString)
            attributedString.font = POSFontStyle.posBodyLargeRegular().font()
            attributedString.foregroundColor = UIColor(Color.posOnSurface)
            return attributedString
        }
        return AttributedString(message)
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                Spacer()
                POSErrorExclamationMark(size: .large)
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text("Invalid coupons")
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)

                    Text(attributedMessage)
                        .padding([.leading, .trailing])
                }
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)
                Button("Continue without coupons", action: {
                    posModel.removeAllCouponsFromCart()
                    retryHandler()
                })
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

@available(iOS 17.0, *)
private extension PointOfSaleOrderSyncCouponsErrorMessageView {
    enum Constants {
        static let headerSpacing: CGFloat = POSSpacing.large
        static let textSpacing: CGFloat = POSSpacing.medium
        static let buttonSidePadding: CGFloat = POSPadding.xxLarge
        static let buttonBottomPadding: CGFloat = POSPadding.medium
    }
}

// MARK: - TODO when copy is finalized
//
//private extension PointOfSaleOrderSyncErrorMessageView {
//    enum Localization {
//        static let title = NSLocalizedString(
//            "pointOfSale.orderSync.couponsError.title",
//            value: "Invalid coupons",
//            comment: "Title of the error when failing to validate coupons and calculate order totals"
//        )
//
//        static let actionTitle = NSLocalizedString(
//            "pointOfSale.orderSync.couponsError.proceed",
//            value: "Continue without coupons",
//            comment: "Button title to remove coupons and retry synchronizing order and calculating order totals"
//        )
//    }
//}

#Preview {
    if #available(iOS 17.0, *) {
        PointOfSaleOrderSyncCouponsErrorMessageView(message: "An error happened!") {}
    }
}
