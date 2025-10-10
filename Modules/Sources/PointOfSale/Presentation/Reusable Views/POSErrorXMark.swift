import SwiftUI

struct POSErrorXMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private let size: POSErrorAndAlertIconSize
    init(size: POSErrorAndAlertIconSize = .large) {
        self.size = size
    }

    var body: some View {
        PointOfSaleAssets.error.decorativeImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: size.dimension)
            .font(.system(size: size.dimension))
            .foregroundStyle(Color.posAlert)
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    HStack {
        POSErrorXMark(size: .small)
        POSErrorXMark(size: .medium)
        POSErrorXMark(size: .large)
    }
}
