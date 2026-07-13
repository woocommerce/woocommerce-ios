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
    }

    private var mark: StoreCheckboxMark {
        if isIndeterminate {
            return .indeterminate
        }
        return isOn ? .checked : .unchecked
    }
}
