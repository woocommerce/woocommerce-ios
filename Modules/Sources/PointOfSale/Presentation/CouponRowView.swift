import SwiftUI

struct CouponRowView: View {
    @Environment(\.posMetrics) private var metrics
    private let couponItem: Cart.CouponItem
    private let couponRowState: CouponRowState?
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding private var showImage: Bool

    init(couponItem: Cart.CouponItem,
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
        metrics.spacing.xSmall * (1 / scale)
    }

    private var dimension: CGFloat {
        min(metrics.cartRowSize * scale, metrics.cartRowSize * Constants.maximumCardSizeMultiplier)
    }

    private var couponImageState: POSCouponImageState {
        switch couponRowState {
        case .invalid:
            .error
        case .valid:
            .success
        default:
            .normal
        }
    }

    var body: some View {
        HStack(spacing: metrics.spacing.medium) {
            POSCouponImageView(size: dimension, state: couponImageState)
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
            .padding(.leading, showImage ? 0 : metrics.padding.medium)
            .accessibilityElement(children: .combine)

            if let onItemRemoveTapped {
                CartRowRemoveButton {
                    onItemRemoveTapped()
                }
            }
        }
        .padding(.trailing, metrics.padding.medium)
        .frame(maxWidth: .infinity, idealHeight: metrics.cartRowSize * scale)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .padding(.horizontal, metrics.padding.medium)
        .geometryGroup()
        .accessibilityIdentifier("pos-cart-coupon-\(couponItem.posItemIdentifier.itemID)")
    }
}

private extension CouponRowView {
    enum Constants {
        static let maximumCardSizeMultiplier: CGFloat = 1.5
        static let titleFont: POSFontStyle = .posBodySmallBold()
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
#Preview(traits: .sizeThatFitsLayout) {
    CouponRowView(couponItem: Cart.CouponItem(id: UUID(),
                                              posItemIdentifier: .init(underlyingType: .coupon, itemID: 123),
                                              code: "10-Discount",
                                              summary: "$10 Off · All products"), couponRowState: .idle) {}
}
#endif
