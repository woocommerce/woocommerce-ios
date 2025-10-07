import SwiftUI

struct POSErrorXMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        PointOfSaleAssets.error.decorativeImage
            .font(.system(size: POSErrorAndAlertIconSize.large.dimension))
            .foregroundStyle(Color.posAlert)
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorXMark()
}
