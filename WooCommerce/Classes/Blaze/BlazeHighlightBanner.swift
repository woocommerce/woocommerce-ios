import SwiftUI

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
            Text("Promote products with Blaze")
                .headlineStyle()

            // Description
            Text("Turn your products into ads that run across millions of sites on WordPress.com and Tumblr.")
                .bodyStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.spacing)

            // CTA
            Button {
                // TODO
            } label: {
                Text("Try Blaze now")
                    .headlineLinkStyle()
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
}

struct BlazeHighlightBanner_Previews: PreviewProvider {
    static var previews: some View {
        BlazeHighlightBanner()
    }
}
