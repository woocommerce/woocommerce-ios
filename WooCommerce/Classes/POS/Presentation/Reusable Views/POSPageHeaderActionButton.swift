import SwiftUI

struct POSPageHeaderActionButton: View {
    let systemName: String
    let action: () -> Void
    @ScaledMetric private var scaledButtonSize: CGFloat = POSHeaderLayoutConstants.minHeight
    private var constrainedButtonSize: CGFloat {
        max(POSHeaderLayoutConstants.minHeight, min(scaledButtonSize, POSHeaderLayoutConstants.minHeight * 1.2))
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(.posSurfaceContainerLow)
                .overlay {
                    Image(systemName: systemName)
                        .font(.posButtonSymbolSmall)
                        .foregroundColor(.posOnSurface)
                        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                }
                .frame(width: constrainedButtonSize, height: constrainedButtonSize)
        }
        .fixedSize()
    }
}
