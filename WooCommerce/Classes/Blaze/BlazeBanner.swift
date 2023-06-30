import SwiftUI
import struct Yosemite.Site

/// Hosting controller for `BlazeHighlightBanner`.
final class BlazeBannerHostingController: UIHostingController<BlazeBanner> {
    private let site: Site
    private let containerViewController: UIViewController
    private let dismissHandler: () -> Void

    init(site: Site,
         entryPoint: EntryPoint,
         containerViewController: UIViewController,
         dismissHandler: @escaping () -> Void) {
        self.site = site
        self.containerViewController = containerViewController
        self.dismissHandler = dismissHandler
        super.init(rootView: BlazeBanner(showsTopDivider: entryPoint.shouldShowTopDivider,
                                         showsBottomSpacer: entryPoint.shouldShowBottomSpacer))
        rootView.onTryBlaze = { [weak self] in
            guard let self else { return }
            // TODO: analytics
            self.showBlaze(onCampaignCreated: dismissHandler)
        }

        rootView.onDismiss = { [weak self] in
            guard let self else { return }
            // TODO: analytics
            self.showDismissAlert(onGotIt: dismissHandler)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showBlaze(onCampaignCreated: @escaping () -> Void) {
        let viewModel = BlazeWebViewModel(source: .menu, site: site, productID: nil, onCampaignCreated: onCampaignCreated)
        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        containerViewController.navigationController?.show(webViewController, sender: self)
    }

    private func showDismissAlert(onGotIt: @escaping () -> Void) {
        let alert = UIAlertController(title: Localization.DismissAlert.title,
                                      message: Localization.DismissAlert.message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: Localization.DismissAlert.gotIt, style: .default) { _ in
            onGotIt()
        }
        alert.addAction(action)
        containerViewController.topmostPresentedViewController.present(alert, animated: true)
    }
}

extension BlazeBannerHostingController {
    enum EntryPoint {
        case myStore
        case products

        var shouldShowTopDivider: Bool {
            switch self {
            case .myStore:
                return false
            case .products:
                return true
            }
        }

        var shouldShowBottomSpacer: Bool {
            switch self {
            case .myStore:
                return false
            case .products:
                return true
            }
        }
    }

    private enum Localization {
        enum DismissAlert {
            static let title = NSLocalizedString(
                "Blaze Ads",
                comment: "Title on the alert presented when dismissing the banner announcing Blaze feature."
            )
            static let message = NSLocalizedString(
                "No worries! Blaze ads are accessible in the Menu and product details' menu for your convenience.",
                comment: "Message on the alert presented when dismissing the banner announcing Blaze feature."
            )
            static let gotIt = NSLocalizedString(
                "Got it",
                comment: "Button on the alert presented when dismissing the banner announcing Blaze feature."
            )
        }
    }
}

/// View to highlight the Blaze feature.
///
struct BlazeBanner: View {
    var showsTopDivider: Bool = false
    var showsBottomSpacer: Bool = false

    /// Closure to be triggered when the Try Blaze now button is tapped.
    var onTryBlaze: () -> Void = {}

    /// Closure to be triggered when the dismiss button is tapped.
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // Optional divider on the top
            Divider()
                .renderedIf(showsTopDivider)

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
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Layout.spacing)

                // CTA
                Button {
                    onTryBlaze()
                } label: {
                    Text(Localization.actionButton)
                        .font(.body.weight(.bold))
                }
                .buttonStyle(LinkButtonStyle())
            }
            .padding(Layout.spacing)

            // Optional spacing at the bottom
            Color(.listBackground)
                .frame(height: Layout.spacing)
                .renderedIf(showsBottomSpacer)
        }
    }
}

private extension BlazeBanner {
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

struct BlazeBanner_Previews: PreviewProvider {
    static var previews: some View {
        BlazeBanner()
    }
}
