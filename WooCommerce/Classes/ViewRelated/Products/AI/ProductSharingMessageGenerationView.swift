import SwiftUI

/// View for generating product sharing message with AI.
struct ProductSharingMessageGenerationView: View {
    @State private var content = ""
    var body: some View {
        VStack(alignment: .center, spacing: Layout.defaultSpacing) {
    
            // Generated message text field
            ZStack(alignment: .topLeading) {
                TextEditor(text: $content)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .background(.clear)
                    .padding(insets: Layout.messageContentInsets)
                    .frame(minHeight: Layout.minimumEditorSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                    )

                // Loading state text
                HStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    Text(Localization.generating)
                        .foregroundColor(Color(.placeholderText))
                        .bodyStyle()
                }
                .padding(insets: Layout.placeholderInsets)
                // Allows gestures to pass through to the `TextEditor`.
                .allowsHitTesting(false)
                .frame(alignment: .center)
            }

            Button(Localization.shareMessage) {
                // TODO
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(Localization.skip) {
                // TODO
            }
            .buttonStyle(LinkButtonStyle())
        }
        .padding(insets: Layout.insets)
    }
}

private extension ProductSharingMessageGenerationView {
    enum Layout {
        static let defaultSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let minimumEditorSize: CGFloat = 76
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
    }
    enum Localization {
        static let generating = NSLocalizedString(
            "Generating share message...",
            comment: "Text showing the loading state of the product sharing message generation screen"
        )
        static let shareMessage = NSLocalizedString(
            "Share message",
            comment: "Action button to share the generated message on the product sharing message generation screen"
        )
        static let skip = NSLocalizedString(
            "Skip to share link only",
            comment: "Action button to skip the generated message on the product sharing message generation screen"
        )
    }
}

struct ProductSharingMessageGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductSharingMessageGenerationView()
    }
}
