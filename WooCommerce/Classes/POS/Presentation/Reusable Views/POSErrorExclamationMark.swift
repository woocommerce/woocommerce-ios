import SwiftUI

struct POSErrorExclamationMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: PointOfSaleCardPresentPaymentLayout.errorIconSize))
            .foregroundStyle(Color(.wooCommerceAmber(.shade60)))
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorExclamationMark()
}
