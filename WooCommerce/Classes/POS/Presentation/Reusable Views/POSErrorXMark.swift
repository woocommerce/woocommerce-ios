import SwiftUI

struct POSErrorXMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        Image(decorative: PointOfSaleAssets.error.imageName)
            .font(.system(size: PointOfSaleCardPresentPaymentLayout.largeErrorIconSize))
            .foregroundStyle(Color.posAlert)
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorXMark()
}
