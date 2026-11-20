import SwiftUI

/// Informational, non-actionable row shown at the bottom of the POS floating-control menu, naming the
/// operator POS is unlocked as (e.g. "Cashier").
struct POSStaffMenuRow: View {
    let staff: POSStaff

    var body: some View {
        Label {
            Text(staff.displayName)
        } icon: {
            Image(systemName: "person.circle")
        }
        .foregroundStyle(.secondary)
        .disabled(true)
        .accessibilityIdentifier("pos-staff-menu-item")
    }
}

#if DEBUG
#Preview {
    POSStaffMenuRow(staff: POSLocalRole.cashier.staff)
        .posPadding(\.medium)
}
#endif
