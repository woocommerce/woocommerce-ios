import SwiftUI

/// Modal shown when the operator taps the read-only "PIN access" toggle in the
/// remote POS staff settings screen. Explains that PIN access is controlled by
/// whether any staff has a PIN (set on the web) and offers a primary call-to-
/// action to jump to the Manage staff web view. Dismiss via the header's X.
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
        VStack(spacing: POSSpacing.xxLarge) {
            PointOfSaleModalHeader(isPresented: $isPresented,
                                   title: .constant(AttributedString(Localization.title)))

            Text(hasAnyPINs ? Localization.disableMessage : Localization.enableMessage)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                isPresented = false
                onManageStaffTapped()
            } label: {
                Text(Localization.manageButton)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(maxWidth: Constants.modalMaxWidth)
        .padding(.horizontal, POSPadding.medium)
    }
}

private extension POSPINAccessInformation {
    enum Constants {
        /// Upper bound for readability on iPad. Shrinks below this on narrower
        /// contexts (e.g. Split View) because the underlying `maxWidth` lets the
        /// container dictate width when less space is available.
        static var modalMaxWidth: CGFloat { 640 }
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.pinAccessModal.title.v2",
            value: "Managed on the web",
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

        static let manageButton = NSLocalizedString(
            "pos.pinAccessModal.manageButton",
            value: "Manage staff on the web",
            comment: "Primary button in the PIN access info modal that opens the Manage staff web view."
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
