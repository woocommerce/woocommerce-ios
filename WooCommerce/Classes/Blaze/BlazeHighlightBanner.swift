import SwiftUI

/// View to highlight the Blaze feature.
///
struct BlazeHighlightBanner: View {
    var body: some View {
        VStack(spacing: Layout.spacing) {
            // Dismiss button
            HStack {
                Spacer()
                Button {
                    // TODO
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            // Blaze icon
            Image(uiImage: .blaze)

            // Title
            Text(Localization.title)
                .headlineStyle()

            // Description
            Text(Localization.description)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.spacing)

            // CTA
            Button {
                // TODO
            } label: {
                Text(Localization.actionButton)
                    .font(.body.weight(.bold))
            }
            .buttonStyle(LinkButtonStyle())
        }
        .padding(Layout.spacing)
    }
}

extension BlazeHighlightBanner {
    enum Layout {
        static let spacing: CGFloat = 16
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Promote products with Blaze",
            comment: "Title on the banner to highlight Blaze feature"
        )
        static let description = NSLocalizedString(
            "Turn your products into ads that run across millions of sites on WordPress.com and Tumblr.",
            comment: "Description on the banner to highlight Blaze feature"
        )
        static let actionButton = NSLocalizedString(
            "Try Blaze now",
            comment: "Title of the button on the banner to highlight Blaze feature"
        )
    }
}

struct BlazeHighlightBanner_Previews: PreviewProvider {
    static var previews: some View {
        BlazeHighlightBanner()
    }
}
