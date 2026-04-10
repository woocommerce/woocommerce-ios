import SwiftUI

/// Renders an edit button with the pencil gridicon image
///
struct PencilEditButton: View {
    @ScaledMetric private var size: CGFloat = Layout.editIconImageSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(uiImage: .pencilImage)
                .resizable()
                .frame(width: size,
                       height: size)
        }
        .accessibilityLabel(Localization.editButtonAccessibilityLabel)
    }
}

private extension PencilEditButton {
    enum Layout {
        static let editIconImageSize: CGFloat = 24
    }

    enum Localization {
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "pencilEditButton.accessibility.editButtonAccessibilityLabel",
            value: "Edit",
            comment: "Accessibility label for the button to edit"
        )
    }
}
