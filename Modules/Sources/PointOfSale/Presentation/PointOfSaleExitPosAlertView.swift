import SwiftUI

struct PointOfSaleExitPosAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        if isCompactWidth {
            compactBody
        } else {
            regularBody
        }
    }

    private var regularBody: some View {
        VStack(spacing: Constants.verticalSpacing) {
            regularCloseButton
            messageContent
            buttons
        }
        .padding(Constants.padding)
    }

    private var compactBody: some View {
        VStack(spacing: POSSpacing.none) {
            compactCloseButton

            Spacer(minLength: POSSpacing.none)

            messageContent

            Spacer(minLength: POSSpacing.none)

            buttons
        }
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var regularCloseButton: some View {
        closeButton(fontStyle: .posButtonSymbolLarge)
    }

    private var compactCloseButton: some View {
        closeButton(fontStyle: .posButtonSymbolMedium)
    }

    private func closeButton(fontStyle: POSFontStyle) -> some View {
        POSModalCloseButton(accessibilityLabel: Localization.closeButtonAccessibilityLabel,
                            accessibilityIdentifier: "pos-exit-modal-close-button",
                            fontStyle: fontStyle) {
            isPresented = false
        }
    }

    private var messageContent: some View {
        VStack(spacing: Constants.verticalSpacing) {
            if isCompactWidth {
                POSErrorXMark(color: .posPrimary)
            }

            VStack(spacing: isCompactWidth ? Constants.compactTitleSpacing : Constants.verticalSpacing) {
                Text(Localization.exitTitle)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                Text(Localization.exitBody)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
            }
        }
    }

    private var buttons: some View {
        POSFlowButtonsView(
            configuration: .init(
                primaryButton: .init(title: Localization.exitButton,
                                     accessibilityIdentifier: "pos-exit-confirm-button",
                                     action: {
                                         analytics.track(.pointOfSaleExitConfirmed)
                                         dismiss()
                                     }),
                secondaryButton: cancelButtonConfig
            )
        )
    }

    /// Regular width keeps the single-button modal, where the close button in the corner is the way out.
    private var cancelButtonConfig: PointOfSaleFlowButtonConfiguration.ButtonConfig? {
        guard isCompactWidth else {
            return nil
        }
        return .init(title: Localization.cancelButton,
                     accessibilityIdentifier: "pos-exit-cancel-button",
                     action: {
                         isPresented = false
                     })
    }
}

private extension PointOfSaleExitPosAlertView {
    enum Constants {
        static let verticalSpacing: CGFloat = POSSpacing.xLarge
        static let compactTitleSpacing: CGFloat = POSSpacing.small
        static let padding: CGFloat = POSPadding.medium
    }

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
        static let cancelButton = NSLocalizedString(
            "pos.exitPOSModal.cancelButton",
            value: "Cancel",
            comment: "Button on the exit Point of Sale modal that dismisses it without exiting Point of Sale."
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
