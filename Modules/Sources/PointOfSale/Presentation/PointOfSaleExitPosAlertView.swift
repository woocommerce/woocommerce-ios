import SwiftUI

struct PointOfSaleExitPosAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        POSConfirmationDialog(title: Localization.exitTitle,
                              message: Localization.exitBody,
                              primaryButton: .init(title: Localization.exitButton,
                                                   accessibilityIdentifier: "pos-exit-confirm-button",
                                                   action: {
                                                       analytics.track(.pointOfSaleExitConfirmed)
                                                       dismiss()
                                                   }),
                              closeButton: .init(accessibilityLabel: Localization.closeButtonAccessibilityLabel,
                                                 accessibilityIdentifier: "pos-exit-modal-close-button",
                                                 action: {
                                                     isPresented = false
                                                 }))
    }
}

private extension PointOfSaleExitPosAlertView {
    enum Localization {
        static let exitTitle = NSLocalizedString(
            "pos.exitPOSModal.exitTitle",
            value: "Exit Point of Sale mode?",
            comment: "Title of the exit Point of Sale modal alert"
        )
        static let exitBody = NSLocalizedString(
            "pos.exitPOSModal.exitBody",
            value: "Any orders in progress will be lost.",
            comment: "Body text of the exit Point of Sale modal alert"
        )
        static let exitButton = NSLocalizedString(
            "pos.exitPOSModal.exitButtom",
            value: "Exit",
            comment: "Button text of the exit Point of Sale modal alert"
        )
        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.exitPOSModal.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for the button to close the exit Point of Sale modal alert."
        )
    }
}

#if DEBUG
#Preview("Compact") {
    PointOfSaleExitPosAlertView(isPresented: .constant(true))
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular") {
    PointOfSaleExitPosAlertView(isPresented: .constant(true))
        .environment(\.horizontalSizeClass, .regular)
}
#endif
