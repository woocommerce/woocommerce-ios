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
                    Text(Localization.title)
                        .foregroundStyle(Color.posOnSurface)
                        .font(.posHeadingBold)

                    Text(attributedMessage)
                        .padding([.leading, .trailing])
                }
                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

                VStack(spacing: POSSpacing.medium) {
                    Button(Localization.retryActionTitle, action: {
                        posModel.removeAllCouponsFromCart()
                        retryHandler()
                    })
                    .buttonStyle(POSFilledButtonStyle(size: .normal))

                    Button(Localization.editOrderTitle, action: {
                        posModel.addMoreToCart()
                    })
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
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

@available(iOS 17.0, *)
private extension PointOfSaleOrderSyncCouponsErrorMessageView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.orderSync.couponsError.title",
            value: "Couldn't apply coupon",
            comment: "Title of the error when failing to validate coupons and calculate order totals"
        )

        static let retryActionTitle = NSLocalizedString(
            "pointOfSale.orderSync.couponsError.removeCoupons",
            value: "Remove coupons",
            comment: "Button title to remove coupons and retry synchronizing order and calculating order totals"
        )

        static let editOrderTitle =  NSLocalizedString(
            "pointOfSale.orderSync.couponsError.editOrder",
            value: "Edit order",
            comment: "Button to come back to order editing when coupon validation fails."
        )
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        PointOfSaleOrderSyncCouponsErrorMessageView(message: "An error happened!") {}
    }
}
