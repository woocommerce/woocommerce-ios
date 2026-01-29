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
            comment: "This text serves as an accessibility label for checkboxes in the Point of Sale interface when they are in a selected state, helping screen readers announce the checkbox status to visually impaired users."
        )

        static let unselectedLabel = NSLocalizedString(
            "pos.checkbox.unselected.accessibilityLabel",
            value: "Not selected",
            comment: "This is an accessibility label for unselected checkbox controls in the Point of Sale interface, used by screen readers to announce the state of checkboxes that are not currently selected."
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
