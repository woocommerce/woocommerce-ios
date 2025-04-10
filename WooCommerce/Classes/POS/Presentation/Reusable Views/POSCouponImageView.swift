import SwiftUI

struct POSCouponImageView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    private var dimension: CGFloat {
        min(Constants.couponCardSize * scale, Constants.maximumCouponCardSize)
    }

    private let size: CGFloat

    init(size: CGFloat) {
        self.size = size
    }

    var body: some View {
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
    }
}

private extension POSCouponImageView {
    enum Constants {
        static let couponCardSize: CGFloat = 96
        static let maximumCouponCardSize: CGFloat = Self.couponCardSize * 1.5
    }
}

#Preview {
    POSCouponImageView(size: POSCouponImageView.Constants.couponCardSize)
}
