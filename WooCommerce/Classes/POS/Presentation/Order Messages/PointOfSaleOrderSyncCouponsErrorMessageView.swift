import SwiftUI

struct PointOfSaleOrderSyncCouponsErrorMessageView: View {
    let message: String
    let retryHandler: () -> Void
    @State private var attributedMessage: AttributedString = ""

    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center, spacing: POSSpacing.none) {
                    Spacer()
                    POSErrorXMark()
                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.imageAndTextSpacing)
                    VStack(alignment: .center, spacing: PointOfSaleEmptyErrorStateViewLayout.textSpacing) {
                        Text(Localization.title)
                            .foregroundStyle(Color.posOnSurface)
                            .font(.posHeadingBold)

                        Text(attributedMessage)
                            .padding([.leading, .trailing])
                    }
                    Spacer().frame(height: PointOfSaleEmptyErrorStateViewLayout.textAndButtonSpacing)

                    VStack(spacing: PointOfSaleEmptyErrorStateViewLayout.buttonSpacing) {
                        Button(Localization.editOrderTitle, action: {
                            posModel.addMoreToCart()
                        })
                        .buttonStyle(POSFilledButtonStyle(size: .normal))

                        Button(retryActionTitle, action: {
                            analytics.track(event: .PointOfSale.itemRemovedFromCart(
                                    sourceView: .error,
                                    itemType: .coupon
                                ))
                            posModel.removeAllItemsFromCart(types: [.coupon])
                            retryHandler()
                        })
                        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    }
                    .frame(width: geometry.size.width / 2)
                    .padding([.leading, .trailing], Constants.buttonSidePadding)
                    .padding([.bottom], Constants.buttonBottomPadding)

                    Spacer()
                }
                .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .onAppear {
            // Setting attributed string once in onAppear to prevent a SwiftUI crash
            // Building attributed HTML string within SwiftUI body causes never-ending redraw cycles
            attributedMessage = message.attributedHTMLString
        }
    }

    private var retryActionTitle: String {
        if posModel.cart.coupons.count == 1 {
            Localization.retryActionTitleSingular
        } else {
            Localization.retryActionTitlePlural
        }
    }
}

private extension PointOfSaleOrderSyncCouponsErrorMessageView {
    enum Constants {
        static let buttonSidePadding: CGFloat = POSPadding.xxLarge
        static let buttonBottomPadding: CGFloat = POSPadding.medium
    }
}

private extension PointOfSaleOrderSyncCouponsErrorMessageView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.orderSync.couponsError.errorTitle.2",
            value: "Unable to apply coupon",
            comment: "Title of the error when failing to validate coupons and calculate order totals"
        )

        static let retryActionTitlePlural = NSLocalizedString(
            "pointOfSale.orderSync.couponsError.removeCoupons",
            value: "Remove coupons",
            comment: "Button title to remove coupons and retry synchronizing order and calculating order totals"
        )

        static let retryActionTitleSingular = NSLocalizedString(
            "pointOfSale.orderSync.couponsError.removeCoupon",
            value: "Remove coupon",
            comment: "Button title to remove a single coupon and retry synchronizing order and calculating order totals"
        )

        static let editOrderTitle =  NSLocalizedString(
            "pointOfSale.orderSync.couponsError.editOrder",
            value: "Edit order",
            comment: "Button to come back to order editing when coupon validation fails."
        )
    }
}

private extension String {
    var attributedHTMLString: AttributedString {
        if let data = self.data(using: .utf8),
           let nsAttributedString = try? NSAttributedString(
               data: data,
               options: [
                   .documentType: NSAttributedString.DocumentType.html,
                   .characterEncoding: String.Encoding.utf8.rawValue
               ],
               documentAttributes: nil) {
            var attributedString = AttributedString(nsAttributedString)
            attributedString.font = POSFontStyle.posBodyLargeRegular().font()
            attributedString.foregroundColor = UIColor(Color.posOnSurface)
            return attributedString
        }
        return AttributedString(self)
    }
}

#if DEBUG
#Preview {
    PointOfSaleOrderSyncCouponsErrorMessageView(message: "An error happened!") {}
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview {
    PointOfSaleOrderSyncCouponsErrorMessageView(message: "Lo sentimos, este cupón no se puede aplicar a los productos seleccionados.") {}
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
