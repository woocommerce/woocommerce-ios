import SwiftUI

struct CouponRowView: View {
    private let couponItem: CartCouponItem
    private let couponRowState: CouponRowState?
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding private var showImage: Bool

    init(couponItem: CartCouponItem,
         couponRowState: CouponRowState? = nil,
         showImage: Binding<Bool> = .constant(true),
         onItemRemoveTapped: (() -> Void)? = nil
    ) {
        self.couponItem = couponItem
        self.couponRowState = couponRowState
        self._showImage = showImage
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    private var dynamicSpacing: CGFloat {
        Constants.titleSummarySpacing * (1 / scale)
    }

    private var dimension: CGFloat {
        min(Constants.couponCardSize * scale, Constants.maximumCouponCardSize)
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
                .frame(width: dimension)
                .frame(minHeight: dimension)
                .accessibilityHidden(true)
                .renderedIf(showImage)

            VStack(alignment: .leading, spacing: dynamicSpacing) {
                Text(couponItem.code)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.titleFont)

                Text(couponItem.summary)
                    .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                    .font(Constants.summaryFont)

                switch couponRowState {
                case .valid(let couponTotal):
                    Text(couponTotal.total)
                        .foregroundColor(.posSuccess)
                        .font(.posBodySmallRegular())
                case .invalid:
                    Text(Localization.invalidCoupon)
                        .foregroundColor(.posError)
                        .font(.posBodySmallRegular())
                case .idle, .validating, .none:
                    EmptyView()
                }
            }
            .animation(.default, value: couponRowState)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, showImage ? 0 : Constants.cardContentHorizontalPadding)
            .accessibilityElement(children: .combine)

            if let onItemRemoveTapped {
                CartRowRemoveButton {
                    onItemRemoveTapped()
                }
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
        static let maximumCouponCardSize: CGFloat = Self.couponCardSize * 1.5
        static let horizontalPadding: CGFloat = POSPadding.medium
        static let horizontalElementSpacing: CGFloat = POSSpacing.medium
        static let cardContentHorizontalPadding: CGFloat = POSPadding.medium
        static let titleFont: POSFontStyle = .posBodySmallBold
        static let titleSummarySpacing: CGFloat = POSSpacing.xSmall
        static let summaryFont: POSFontStyle = .posBodySmallRegular()
    }
}

private extension CouponRowView {
    private enum Localization {
        static let invalidCoupon = NSLocalizedString(
            "pointOfSale.couponRow.invalidCoupon",
            value: "Coupon not applied",
            comment: "A message shown on the coupon if's not valid after attempting to apply it")
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    CouponRowView(couponItem: CartCouponItem(id: UUID(), code: "10-Discount", summary: "$10 Off · All products"), couponRowState: .idle) {}
}
#endif
