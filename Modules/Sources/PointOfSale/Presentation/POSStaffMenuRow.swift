import SwiftUI

/// Informational, non-actionable row shown at the bottom of the POS floating-control menu, naming the
/// signed-in staff member as "Name - Role" (e.g. "Thomas - Cashier").
struct POSStaffMenuRow: View {
    let staff: POSStaff

    var body: some View {
        Label {
            Text(label)
                .lineLimit(2)
        } icon: {
            Image(systemName: "person.circle")
        }
        .foregroundStyle(.secondary)
        .disabled(true)
        .accessibilityIdentifier("pos-staff-menu-item")
    }

    private var label: String {
        String.localizedStringWithFormat(Localization.staffLabelFormat, staff.displayName, staff.preset.displayName)
    }
}

private extension POSStaffMenuRow {
    enum Localization {
        static let staffLabelFormat = NSLocalizedString(
            "pointOfSale.floatingButtons.staff.labelFormat",
            value: "%1$@ - %2$@",
            comment: "Format for the signed-in POS staff member shown in the menu: name, then role, " +
            "e.g. \"Thomas - Cashier\". %1$@ is the staff name, %2$@ is the role."
        )
    }
}

#if DEBUG
#Preview {
    POSStaffMenuRow(staff: POSStaff(userID: 1, displayName: "Thomas", preset: .cashier, capabilities: []))
        .padding()
}
#endif
