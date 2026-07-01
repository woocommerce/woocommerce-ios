import SwiftUI

/// Informational, non-actionable row shown at the bottom of the POS floating-control menu, naming the
/// signed-in staff member as "Name - Role" (e.g. "Thomas - Cashier").
struct POSStaffMenuRow: View {
    let staff: POSStaff

    var body: some View {
        Label {
            Text(displayLabel)
        } icon: {
            Image(systemName: "person.circle")
        }
        .foregroundStyle(.secondary)
        .disabled(true)
        .accessibilityIdentifier("pos-staff-menu-item")
        // The row renders inside a system menu (UIMenu), which ignores SwiftUI's line-limit and
        // truncation modifiers — so we truncate `displayLabel` ourselves. Read the full text aloud.
        .accessibilityLabel(fullLabel)
    }

    private var fullLabel: String {
        String.localizedStringWithFormat(Localization.staffLabelFormat, staff.displayName, staff.preset.displayName)
    }

    /// System menus truncate long labels at the trailing edge and can wrap to several lines, so
    /// middle-truncate the string to keep the start of the name and the trailing role visible.
    private var displayLabel: String {
        fullLabel.middleTruncated(maxLength: Constants.maxLabelLength)
    }
}

private extension POSStaffMenuRow {
    enum Constants {
        static let maxLabelLength = 30
    }

    enum Localization {
        static let staffLabelFormat = NSLocalizedString(
            "pointOfSale.floatingButtons.staff.labelFormat",
            value: "%1$@ - %2$@",
            comment: "Format for the signed-in POS staff member shown in the menu: name, then role, " +
            "e.g. \"Thomas - Cashier\". %1$@ is the staff name, %2$@ is the role."
        )
    }
}

private extension String {
    /// Collapses the middle into an ellipsis when longer than `maxLength`, keeping the start and end
    /// visible — a manual stand-in for `.truncationMode(.middle)`, which system menus ignore.
    func middleTruncated(maxLength: Int) -> String {
        guard count > maxLength else {
            return self
        }
        let kept = max(maxLength - 1, 2)
        let head = (kept + 1) / 2
        let tail = kept - head
        return "\(prefix(head))…\(suffix(tail))"
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        POSStaffMenuRow(staff: POSStaff(userID: 1, displayName: "Thomas", preset: .cashier, capabilities: []))
        POSStaffMenuRow(staff: POSStaff(userID: 2,
                                        displayName: "Alexander Bartholomew Montgomery",
                                        preset: .manager,
                                        capabilities: []))
    }
    .padding()
}
#endif
