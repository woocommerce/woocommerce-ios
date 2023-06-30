import SwiftUI
import struct Yosemite.Site

/// Hosting controller for `BlazeHighlightBanner`.
final class BlazeBannerHostingController: UIHostingController<BlazeBanner> {
    init(site: Site,
         entryPoint: EntryPoint,
         parentViewController: UIViewController) {
        super.init(rootView: BlazeBanner())
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BlazeBannerHostingController {
    enum EntryPoint {
        case myStore
        case products
    }
}

/// View to highlight the Blaze feature.
///
struct BlazeBanner: View {
    /// Closure to be triggered when the Try Blaze now button is tapped.
    var onBlaze: () -> Void = {}

    /// Closure to be triggered when the dismiss button is tapped.
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: Layout.spacing) {
            // Dismiss button
            HStack {
                Spacer()
                Button {
                    onDismiss()
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
                onBlaze()
            } label: {
                Text(Localization.actionButton)
                    .font(.body.weight(.bold))
            }
            .buttonStyle(LinkButtonStyle())
        }
        .padding(Layout.spacing)
    }
}

extension BlazeBanner {
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
        BlazeBanner()
    }
}
