import SwiftUI

struct POSErrorXMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: PointOfSaleCardPresentPaymentLayout.largeErrorIconSize))
            .foregroundStyle(Color(.wooCommerceAmber(.shade60)))
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorXMark()
}
