import SwiftUI

struct POSErrorExclamationMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let size: CGFloat
    init(size: CGFloat = PointOfSaleCardPresentPaymentLayout.errorIconSize) {
        self.size = size
    }

    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: size))
            .foregroundStyle(Color(.wooCommerceAmber(.shade60)))
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorExclamationMark()
}
