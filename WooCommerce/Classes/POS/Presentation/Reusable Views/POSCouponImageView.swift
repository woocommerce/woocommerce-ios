import SwiftUI

struct POSCouponImageView: View {
    private let size: CGFloat

    init(size: CGFloat) {
        self.size = size
    }

    var body: some View {
        Rectangle()
            .foregroundColor(.posSurfaceDim)
            .overlay {
                Image(systemName: "tag")
                    .font(.posButtonSymbolMedium)
                    .foregroundColor(.posOnSurfaceVariantLowest)
            }
            .frame(width: size)
            .frame(minHeight: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    POSCouponImageView(size: 100)
}
