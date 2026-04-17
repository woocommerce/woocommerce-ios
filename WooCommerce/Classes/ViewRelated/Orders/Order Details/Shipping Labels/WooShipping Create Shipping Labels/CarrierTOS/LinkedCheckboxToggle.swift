import SwiftUI

/// A checkbox toggle with an embedded link in its label.
///
/// Renders a `Toggle` styled as a checkbox using `CheckboxToggleStyle`.
/// The label text contains a tappable link created via `AttributedString.withEmbeddedLink`.
///
struct LinkedCheckboxToggle: View {
    @Binding var isOn: Bool

    /// Format string containing a `%1$@` placeholder for the link text.
    let labelFormat: String

    /// The visible link text that replaces the placeholder in `labelFormat`.
    let linkText: String

    /// The URL string the link opens.
    let linkURL: String

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(
                AttributedString.withEmbeddedLink(
                    mainContent: labelFormat,
                    linkText: linkText,
                    link: linkURL
                )
            )
        }
        .toggleStyle(CheckboxToggleStyle())
    }
}
