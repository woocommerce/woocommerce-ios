import SwiftUI

extension View {
    func posModalCloseButton(
        action: @escaping (() -> Void),
        accessibilityLabel: String = POSModalCloseButton.Localization.defaultAccessibilityLabel) -> some View {
        self.modifier(
            POSModalCloseButtonModifier(
                closeAction: action,
                accessibilityLabel: accessibilityLabel)
            )
    }
}

struct POSModalCloseButton: View {
    let accessibilityLabel: String
    let closeAction: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: closeAction, label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolMedium)
            })
            .foregroundColor(Color.posOnSurface)
            .accessibilityLabel(accessibilityLabel)
        }
    }
}

struct POSModalCloseButtonModifier: ViewModifier {
    let closeAction: () -> Void
    let accessibilityLabel: String

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            POSModalCloseButton(accessibilityLabel: accessibilityLabel, closeAction: closeAction)

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
