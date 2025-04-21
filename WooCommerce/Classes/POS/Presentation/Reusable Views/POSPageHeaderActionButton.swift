import SwiftUI

struct POSPageHeaderActionButton<Label: View>: View {
    let label: Label
    let action: () -> Void
    @ScaledMetric private var scaledButtonSize: CGFloat = POSHeaderLayoutConstants.minHeight
    private var constrainedButtonSize: CGFloat {
        max(POSHeaderLayoutConstants.minHeight, min(scaledButtonSize, POSHeaderLayoutConstants.minHeight * 1.2))
    }

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(.posSurfaceContainerLow)
                .overlay {
                    label
                        .font(.posButtonSymbolSmall)
                        .foregroundColor(.posOnSurface)
                        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                }
                .frame(width: constrainedButtonSize, height: constrainedButtonSize)
        }
        .fixedSize()
    }
}

// Convenience initializer for backward compatibility
extension POSPageHeaderActionButton where Label == Image {
    init(systemName: String, action: @escaping () -> Void) {
        self.init(action: action) {
            Image(systemName: systemName)
        }
    }
}
