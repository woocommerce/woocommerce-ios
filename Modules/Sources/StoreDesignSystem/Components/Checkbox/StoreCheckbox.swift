import SwiftUI

public struct StoreCheckbox: View {
    @Binding private var isOn: Bool
    private let isIndeterminate: Bool
    private let variant: StoreCheckboxVariant

    public init(isOn: Binding<Bool>,
                isIndeterminate: Bool = false,
                variant: StoreCheckboxVariant = .default) {
        self._isOn = isOn
        self.isIndeterminate = isIndeterminate
        self.variant = variant
    }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            EmptyView()
        }
        .buttonStyle(StoreCheckboxStyle(mark: mark, variant: variant))
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(accessibilityValue)
    }

    private var mark: StoreCheckboxMark {
        if isIndeterminate {
            return .indeterminate
        }
        return isOn ? .checked : .unchecked
    }

    private var accessibilityValue: String {
        switch mark {
        case .checked:
            return Localization.checked
        case .unchecked:
            return Localization.unchecked
        case .indeterminate:
            return Localization.mixed
        }
    }
}

private extension StoreCheckbox {
    enum Localization {
        static let checked = NSLocalizedString(
            "storeCheckbox.accessibilityValue.checked",
            value: "Checked",
            comment: "VoiceOver value announced for a selected checkbox."
        )
        static let unchecked = NSLocalizedString(
            "storeCheckbox.accessibilityValue.unchecked",
            value: "Unchecked",
            comment: "VoiceOver value announced for an unselected checkbox."
        )
        static let mixed = NSLocalizedString(
            "storeCheckbox.accessibilityValue.mixed",
            value: "Mixed",
            comment: "VoiceOver value announced for a checkbox in the indeterminate (partially selected) state."
        )
    }
}
