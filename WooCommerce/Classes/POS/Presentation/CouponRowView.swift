import SwiftUI

struct CouponRowView: View {
    private let couponItem: CartCouponItem
    private let couponRowState: CouponRowState?
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0

    init(couponItem: CartCouponItem, couponRowState: CouponRowState? = nil, onItemRemoveTapped: (() -> Void)? = nil) {
        self.couponItem = couponItem
        self.couponRowState = couponRowState
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    private var dynamicSpacing: CGFloat {
        Constants.titleSummarySpacing * (1 / scale)
    }

    var body: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            Rectangle()
                .foregroundColor(.posSurfaceDim)
                .overlay {
                    Text(Image(systemName: "tag"))
                        .font(.posButtonSymbolMedium)
                        .foregroundColor(.posOnSurfaceVariantLowest)
                }
                .frame(width: Constants.couponCardSize, height: Constants.couponCardSize)

            VStack(alignment: .leading, spacing: dynamicSpacing) {
                Text(couponItem.code)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.titleFont)

                Text(couponItem.summary)
                    .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                    .font(Constants.summaryFont)

                switch couponRowState {
                case .valid(let couponTotal):
                    Text("-\(couponTotal.total)")
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.summaryFont)
                case .idle, .none:
                    EmptyView()
                case .invalid:
                    Text("Invalid coupon")
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.summaryFont)
                case .validating:
                    Text("Validating...")
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.summaryFont)
                }
            }
            .animation(.default, value: couponRowState)
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
        static let titleFont: POSFontStyle = .posBodySmallBold
        static let titleSummarySpacing: CGFloat = POSSpacing.xSmall
        static let summaryFont: POSFontStyle = .posBodySmallRegular()
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    CouponRowView(couponItem: CartCouponItem(id: UUID(), code: "10-Discount", summary: "$10 Off · All products"), couponRowState: .idle) {}
}
#endif
