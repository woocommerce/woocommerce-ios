import SwiftUI

extension View {
    func posModalCloseButton(
        action: @escaping (() -> Void),
        accessibilityLabel: String = POSModalCloseButton.Localization.defaultAccessibilityLabel) -> some View {
        self.modifier(
            POSModalCloseButton(
                closeAction: action,
                accessibilityLabel: accessibilityLabel)
            )
    }
}

struct POSModalCloseButton: ViewModifier {
    let closeAction: () -> Void
    let accessibilityLabel: String

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: closeAction, label: {
                    Image(systemName: "xmark")
                        .font(.posButtonSymbol)
                })
                .foregroundColor(Color.posTertiaryText)
                .accessibilityLabel(accessibilityLabel)
            }

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
