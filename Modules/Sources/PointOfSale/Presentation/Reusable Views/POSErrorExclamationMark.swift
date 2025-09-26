import SwiftUI

struct POSErrorExclamationMark: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let size: POSErrorAndAlertIconSize
    init(size: POSErrorAndAlertIconSize = .medium) {
        self.size = size
    }

    var body: some View {
        PointOfSaleAssets.exclamationMark.decorativeImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: size.dimension)
            .layoutPriority(-1)
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    HStack {
        POSErrorExclamationMark(size: .small)
        POSErrorExclamationMark(size: .medium)
        POSErrorExclamationMark(size: .large)
    }
}
