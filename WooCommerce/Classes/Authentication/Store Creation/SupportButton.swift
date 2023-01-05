import SwiftUI

/// A support button with a help icon that is currently shown in the navigation bar.
struct SupportButton: View {
    let onTapped: () -> Void

    var body: some View {
        Button {
            onTapped()
        } label: {
            Image(uiImage: .helpOutlineImage)
                .renderingMode(.template)
                .linkStyle()
        }
        .accessibilityLabel(Localization.accessibilityLabel)
    }
}

private extension SupportButton {
    enum Localization {
        static let accessibilityLabel = NSLocalizedString(
            "Help & Support",
            comment: "Accessibility label for the Help & Support image navigation bar button in the store creation flow."
        )
    }
}

struct SupportButton_Previews: PreviewProvider {
    static var previews: some View {
        SupportButton(onTapped: {})
    }
}
