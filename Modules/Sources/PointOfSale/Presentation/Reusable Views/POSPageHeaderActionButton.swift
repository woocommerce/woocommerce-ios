import SwiftUI

struct POSPageHeaderActionButton: View {
    let systemName: String
    var backgroundColor: Color = .posSurfaceContainerLow
    var imageColor: Color = .posOnSurface
    let action: () -> Void

    @ScaledMetric private var scaledButtonSize: CGFloat = POSHeaderLayoutConstants.minHeight
    private var constrainedButtonSize: CGFloat {
        max(POSHeaderLayoutConstants.minHeight, min(scaledButtonSize, POSHeaderLayoutConstants.minHeight * 1.2))
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(backgroundColor)
                .overlay {
                    Image(systemName: systemName)
                        .font(.posButtonSymbolSmall)
                        .foregroundColor(imageColor)
                        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                }
                .frame(width: constrainedButtonSize, height: constrainedButtonSize)
        }
        .fixedSize()
    }
}
