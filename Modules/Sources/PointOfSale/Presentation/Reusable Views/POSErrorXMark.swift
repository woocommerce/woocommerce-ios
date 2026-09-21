import SwiftUI

struct POSErrorXMark: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private let size: POSErrorAndAlertIconSize
    private let color: Color

    init(size: POSErrorAndAlertIconSize = .large, color: Color = .posAlert) {
        self.size = size
        self.color = color
    }

    var body: some View {
        PointOfSaleAssets.error.decorativeImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: size.dimension)
            .font(.system(size: size.dimension))
            .foregroundStyle(color)
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
