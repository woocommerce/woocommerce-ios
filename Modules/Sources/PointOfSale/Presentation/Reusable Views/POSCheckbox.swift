import SwiftUI

struct POSCheckbox: View {
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                        .fill(Color.posPrimaryContainer)
                        .frame(width: Constants.size, height: Constants.size)
                    Image(systemName: "checkmark")
                        .font(.posButtonSymbolXSmall)
                        .foregroundColor(.posOnPrimaryContainer)
                } else {
                    RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value)
                        .strokeBorder(Color.posOutline, lineWidth: 2)
                        .frame(width: Constants.size, height: Constants.size)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(isSelected ? Localization.selectedLabel : Localization.unselectedLabel)
    }
}

private extension POSCheckbox {
    enum Constants {
        static let size: CGFloat = 32
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
        VStack(spacing: 20) {
            POSCheckbox(isSelected: isSelected, onToggle: { isSelected.toggle() })
            POSCheckbox(isSelected: false, onToggle: {})
        }
        .padding()
        .background(Color.posSurfaceBright)
    }
}

#Preview("POSCheckbox") {
    POSCheckboxPreviewWrapper()
}
#endif
