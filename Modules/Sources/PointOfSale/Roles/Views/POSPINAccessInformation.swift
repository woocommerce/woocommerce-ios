import SwiftUI

/// Modal shown when the operator taps the read-only "PIN access" toggle in the
/// remote POS staff settings screen. Explains that PIN access is controlled by
/// whether any staff has a PIN (set on the web) and offers a direct jump to the
/// Manage staff web view.
///
/// Uses the same `PointOfSaleInformationModal` shell as the "Where are my
/// products?" modal for visual consistency.
struct POSPINAccessInformation: View {
    @Binding var isPresented: Bool
    let hasAnyPINs: Bool
    let onManageStaffTapped: () -> Void

    init(isPresented: Binding<Bool>,
         hasAnyPINs: Bool,
         onManageStaffTapped: @escaping () -> Void) {
        self._isPresented = isPresented
        self.hasAnyPINs = hasAnyPINs
        self.onManageStaffTapped = onManageStaffTapped
    }

    var body: some View {
        PointOfSaleInformationModal(isPresented: $isPresented,
                                    title: AttributedString(Localization.title)) {
            PointOfSaleInformationModalParagraphView {
                Text(hasAnyPINs ? Localization.disableMessage : Localization.enableMessage)
            }

            PointOfSaleInformationModalParagraphView(style: .outlined) {
                Text(Localization.manageHint)

                Spacer().frame(height: POSSpacing.small)

                Button {
                    isPresented = false
                    onManageStaffTapped()
                } label: {
                    Label(Localization.manageButton, systemImage: "safari")
                        .font(.posBodySmallRegular())
                }
                .foregroundStyle(Color.posPrimary)
            }
        }
    }
}

private extension POSPINAccessInformation {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.pinAccessModal.title",
            value: "PIN access is managed on the web",
            comment: "Title of the modal explaining that POS PIN access is controlled via the web admin."
        )

        static let enableMessage = NSLocalizedString(
            "pos.pinAccessModal.message.enable",
            value: "PIN access turns on automatically as soon as any staff member has a PIN. Set a PIN for a staff member to turn it on.",
            comment: "Message shown when the operator tries to turn on PIN access from the POS app."
        )

        static let disableMessage = NSLocalizedString(
            "pos.pinAccessModal.message.disable",
            value: "To turn PIN access off, remove the PIN from every staff member.",
            comment: "Message shown when the operator tries to turn off PIN access from the POS app."
        )

        static let manageHint = NSLocalizedString(
            "pos.pinAccessModal.manageHint",
            value: "Manage staff PINs in WooCommerce \u{203A} Settings \u{203A} Point of sale \u{203A} Staff.",
            comment: "Hint directing the operator to the Manage staff web view. The '\u{203A}' separator is a single-character right-pointing angle quote."
        )

        static let manageButton = NSLocalizedString(
            "pos.pinAccessModal.manageButton",
            value: "Manage staff on the web",
            comment: "Button in the PIN access info modal that opens the Manage staff web view."
        )
    }
}

#if DEBUG
#Preview("PIN access ON") {
    POSPINAccessInformation(
        isPresented: .constant(true),
        hasAnyPINs: true,
        onManageStaffTapped: {}
    )
}

#Preview("PIN access OFF") {
    POSPINAccessInformation(
        isPresented: .constant(true),
        hasAnyPINs: false,
        onManageStaffTapped: {}
    )
}
#endif
