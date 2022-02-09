import SwiftUI
import SafariServices

/// Hosting controller wrapper for `StorePickerError`
///
final class StorePickerErrorHostingController: UIHostingController<StorePickerError> {

    /// Creates an `StorePickerErrorHostingController` with preconfigured button actions.
    ///
    static func createWithActions(presenting: UIViewController) -> StorePickerErrorHostingController {
        let viewController = StorePickerErrorHostingController()
        viewController.setActions(troubleshootingAction: {
            let safariViewController = SFSafariViewController(url: WooConstants.URLs.troubleshootErrorLoadingData.asURL())
            viewController.present(safariViewController, animated: true)
        },
        contactSupportAction: {
            presenting.dismiss(animated: true) {
                ZendeskProvider.shared.showNewRequestIfPossible(from: presenting)
            }
        },
        dismissAction: {
            presenting.dismiss(animated: true)
        })
        return viewController
    }

    init() {
        super.init(rootView: StorePickerError())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Allows the view have a clear background when a custom presentation context
        view.backgroundColor = modalPresentationStyle == .custom ? .clear : view.backgroundColor
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Actions are set in a separate function because most of the time, they will require to access `self` to be able to present new view controllers.
    ///
    func setActions(troubleshootingAction: @escaping () -> Void, contactSupportAction: @escaping () -> Void, dismissAction: @escaping () -> Void) {
        rootView.troubleshootingAction = troubleshootingAction
        rootView.contactSupportAction = contactSupportAction
        rootView.dismissAction = dismissAction
    }
}

/// Generic Store Picker error view that allows the user to contact support.
///
struct StorePickerError: View {

    /// Closure invoked when the "Troubleshooting" button is pressed
    ///
    var troubleshootingAction: () -> Void = {}

    /// Closure invoked when the "Contact Support" button is pressed
    ///
    var contactSupportAction: () -> Void = {}

    /// Closure invoked when the "Back To Sites" button is pressed
    ///
    var dismissAction: () -> Void = {}

    var body: some View {
        // Adds an outer transparent padding and constraints the view max width
        Group {
            VStack(alignment: .center, spacing: Layout.mainVerticalSpacing) {
                // Title
                Text(Localization.title)
                    .headlineStyle()

                // Main image
                Image(uiImage: .errorImage)

                // Body text
                Text(Localization.body)
                    .multilineTextAlignment(.center)
                    .bodyStyle()

                VStack(spacing: Layout.buttonsSpacing) {
                    // Primary Button
                    Button(Localization.troubleshoot, action: troubleshootingAction)
                        .buttonStyle(PrimaryButtonStyle())
                        .fixedSize(horizontal: false, vertical: true)

                    // Secondary button
                    Button(Localization.contact, action: contactSupportAction)
                        .buttonStyle(SecondaryButtonStyle())
                        .fixedSize(horizontal: false, vertical: true)

                    // Dismiss button
                    Button(Localization.back, action: dismissAction)
                        .buttonStyle(LinkButtonStyle())
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding([.leading, .trailing, .bottom])
            .padding(.top, Layout.topPadding)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(Layout.rounderCorners)
        }
        .padding(Layout.outerSidePadding)
        .background(Color.clear)
        .scrollVerticallyIfNeeded()
        .frame(maxWidth: Layout.maxModalWidth)
    }
}

// MARK: Constant

private extension StorePickerError {
    enum Localization {
        static let title = NSLocalizedString("We couldn't load your site", comment: "Title for the default store picker error screen")
        static let body = NSLocalizedString("Please try again or reach out to us and we'll be happy to assist you!",
                                            comment: "Body text for the default store picker error screen")
        static let troubleshoot = NSLocalizedString("Read our Troubleshooting Tips",
                                                    comment: "Text for the button to navigate to troubleshooting tips from the store picker error screen")
        static let contact = NSLocalizedString("Contact Support",
                                               comment: "Text for the button to contact support from the store picker error screen")
        static let back = NSLocalizedString("Back to Sites",
                                            comment: "Text for the button to dismiss the store picker error screen")
    }

    enum Layout {
        static let rounderCorners: CGFloat = 10
        static let mainVerticalSpacing: CGFloat = 25
        static let buttonsSpacing: CGFloat = 15
        static let topPadding: CGFloat = 30
        static let outerSidePadding: CGFloat = 16
        static let maxModalWidth: CGFloat = 475
    }
}

// MARK: Previews

struct StorePickerError_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            StorePickerError()
        }
        .padding()
        .background(Color.gray)
        .previewLayout(.sizeThatFits)

        VStack {
            StorePickerError()
        }
        .padding()
        .background(Color.gray)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }
}
