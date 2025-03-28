import SwiftUI

struct CouponRowView: View {
    private let couponItem: CartCouponItem
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0

    init(couponItem: CartCouponItem, onItemRemoveTapped: (() -> Void)? = nil) {
        self.couponItem = couponItem
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    var body: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            Rectangle()
                .foregroundColor(.posSurfaceDim)
                .overlay {
                    Text(Image(systemName: "tag.square.fill"))
                        .font(.posButtonSymbolLarge)
                        .foregroundColor(.posOnSurfaceVariantLowest)
                }
                .frame(width: Constants.couponCardSize, height: Constants.couponCardSize)

            VStack(alignment: .leading) {
                Text(couponItem.code)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.itemTitleFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onItemRemoveTapped {
                Button(action: {
                    onItemRemoveTapped()
                }, label: {
                    Text(Image(systemName: "xmark.circle"))
                        .font(.posButtonSymbolMedium)
                })
                .foregroundColor(Color.posOnSurfaceVariantLowest)
            }
        }
        .padding(.trailing, Constants.cardContentHorizontalPadding)
        .frame(maxWidth: .infinity, idealHeight: Constants.couponCardSize * scale)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

private extension CouponRowView {
    enum Constants {
        static let couponCardSize: CGFloat = 96
        static let horizontalPadding: CGFloat = POSPadding.medium
        static let horizontalElementSpacing: CGFloat = POSSpacing.medium
        static let cardContentHorizontalPadding: CGFloat = POSPadding.medium
        static let itemTitleFont: POSFontStyle = .posBodySmallBold
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    CouponRowView(couponItem: CartCouponItem(id: UUID(), code: "10-Discount")) {}
}
#endif
