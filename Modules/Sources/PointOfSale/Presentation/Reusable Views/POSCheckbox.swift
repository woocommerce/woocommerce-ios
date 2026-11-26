import SwiftUI

struct POSCheckbox: View {
    @Environment(\.posMetrics) private var metrics
    let isSelected: Bool
    let onToggle: () -> Void

    private var size: CGFloat {
        metrics.checkboxSize
    }

    private var tapTargetOutset: CGFloat {
        max((Constants.minimumTapTargetSize - size) / 2, 0)
    }

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                        .fill(Color.posPrimaryContainer)
                        .frame(width: size, height: size)
                    Image(systemName: "checkmark")
                        .font(.posButtonSymbolXSmall)
                        .foregroundColor(.posOnPrimaryContainer)
                } else {
                    RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                        .strokeBorder(Color.posOutline, lineWidth: 2)
                        .frame(width: size, height: size)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .frame(width: size + tapTargetOutset * 2, height: size + tapTargetOutset * 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The tap area overflows the box, so rows still lay out around the visible box size.
        .padding(-tapTargetOutset)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(isSelected ? Localization.selectedLabel : Localization.unselectedLabel)
    }
}

private extension POSCheckbox {
    enum Constants {
        static let minimumTapTargetSize: CGFloat = 44
    }
}

private extension POSCheckbox {
    enum Localization {
        static let selectedLabel = NSLocalizedString(
            "pos.checkbox.selected.accessibilityLabel",
            value: "Selected",
            comment: "Accessibility label for a selected checkbox"
        )

        static let unselectedLabel = NSLocalizedString(
            "pos.checkbox.unselected.accessibilityLabel",
            value: "Not selected",
            comment: "Accessibility label for an unselected checkbox"
        )
    }
}

#if DEBUG
struct POSCheckboxPreviewWrapper: View {
    @State private var isSelected = true

    var body: some View {
        VStack(spacing: POSMetrics.regular.spacing.large) {
            POSCheckbox(isSelected: isSelected, onToggle: { isSelected.toggle() })
            POSCheckbox(isSelected: false, onToggle: {})
        }
        .posPadding(\.medium)
        .background(Color.posSurfaceBright)
    }
}

#Preview("POSCheckbox") {
    POSCheckboxPreviewWrapper()
}
#endif
