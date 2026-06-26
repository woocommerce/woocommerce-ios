import SwiftUI

extension View {
    func posModalCloseButton(
        action: @escaping (() -> Void),
        accessibilityLabel: String = POSModalCloseButton.Localization.defaultAccessibilityLabel,
        accessibilityIdentifier: String? = nil,
        fontStyle: POSFontStyle = .posButtonSymbolMedium,
        foregroundColor: Color = .posOnSurface) -> some View {
        self.modifier(
            POSModalCloseButtonModifier(
                closeAction: action,
                accessibilityLabel: accessibilityLabel,
                accessibilityIdentifier: accessibilityIdentifier,
                fontStyle: fontStyle,
                foregroundColor: foregroundColor)
            )
    }
}

struct POSModalCloseButton: View {
    let accessibilityLabel: String
    let accessibilityIdentifier: String?
    let fontStyle: POSFontStyle
    let foregroundColor: Color
    let closeAction: () -> Void

    init(accessibilityLabel: String = Localization.defaultAccessibilityLabel,
         accessibilityIdentifier: String? = nil,
         fontStyle: POSFontStyle = .posButtonSymbolMedium,
         foregroundColor: Color = .posOnSurface,
         closeAction: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.fontStyle = fontStyle
        self.foregroundColor = foregroundColor
        self.closeAction = closeAction
    }

    var body: some View {
        HStack {
            Spacer()
            button
        }
    }

    @ViewBuilder
    private var button: some View {
        let button = Button(action: closeAction, label: {
            Text(Image(systemName: "xmark"))
                .font(fontStyle)
        })
        .foregroundColor(foregroundColor)
        .accessibilityLabel(accessibilityLabel)
        .accessibilitySortPriority(-1)

        if let accessibilityIdentifier {
            button.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            button
        }
    }
}

struct POSModalCloseButtonModifier: ViewModifier {
    let closeAction: () -> Void
    let accessibilityLabel: String
    let accessibilityIdentifier: String?
    let fontStyle: POSFontStyle
    let foregroundColor: Color

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            POSModalCloseButton(accessibilityLabel: accessibilityLabel,
                                accessibilityIdentifier: accessibilityIdentifier,
                                fontStyle: fontStyle,
                                foregroundColor: foregroundColor,
                                closeAction: closeAction)

            Spacer()

            content

            Spacer()
        }
    }
}

private extension POSModalCloseButton {
    enum Localization {
        static let defaultAccessibilityLabel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.connection.modal.close.button.accessibilityLabel.default",
            value: "Close",
            comment: "The default accessibility label for an `x` close button on a card reader connection modal.")
    }
}
