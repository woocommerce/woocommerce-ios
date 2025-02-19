import SwiftUI

struct POSErrorExclamationMark: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let size: CGFloat
    init(size: CGFloat = PointOfSaleCardPresentPaymentLayout.errorIconSize) {
        self.size = size
    }

    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: size)
            .layoutPriority(-1)
            .foregroundStyle(Color.posAlert)
            .accessibilityHidden(true)
            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
    }
}

#Preview {
    POSErrorExclamationMark()
}
