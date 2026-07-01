import SwiftUI

/// Informational, non-actionable row shown at the bottom of the POS floating-control menu, naming the
/// signed-in operator as "Name - Role" (e.g. "Thomas - Cashier").
struct POSOperatorMenuRow: View {
    let staff: POSStaff

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Image(systemName: "person.circle")
        }
        .foregroundStyle(.secondary)
        .disabled(true)
        .accessibilityIdentifier("pos-operator-menu-item")
    }

    private var label: String {
        String.localizedStringWithFormat(Localization.operatorLabelFormat, staff.displayName, staff.preset.displayName)
    }
}

private extension POSOperatorMenuRow {
    enum Localization {
        static let operatorLabelFormat = NSLocalizedString(
            "pointOfSale.floatingButtons.operator.labelFormat",
            value: "%1$@ - %2$@",
            comment: "Format for the signed-in POS operator shown in the menu: name, then role, " +
            "e.g. \"Thomas - Cashier\". %1$@ is the staff name, %2$@ is the role."
        )
    }
}

#if DEBUG
#Preview {
    POSOperatorMenuRow(staff: POSStaff(userID: 1, displayName: "Thomas", preset: .cashier, capabilities: []))
        .padding()
}
#endif
