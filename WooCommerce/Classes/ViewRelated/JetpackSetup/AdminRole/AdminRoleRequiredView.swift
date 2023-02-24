import SwiftUI

/// Hosting controller that wraps the `AdminRoleRequiredView`.
final class AdminRoleRequiredHostingController: UIHostingController<AdminRoleRequiredView> {
    init(onClose: @escaping () -> Void) {
        super.init(rootView: AdminRoleRequiredView(viewModel: .init(), onClose: onClose))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }
}

/// Error view displayed when a user without admin role tries to install Jetpack.
struct AdminRoleRequiredView: View {
    let onClose: () -> Void

    private let viewModel: AdminRoleRequiredViewModel

    /// Provides the URL destination when the link button is tapped
    private let linkDestinationURL = WooConstants.URLs.rolesAndPermissionsInfo.asURL()

    @State private var showingLinkContent = false

    init(viewModel: AdminRoleRequiredViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 16) {
            // Username and role
            VStack(spacing: 3) {
                Text(viewModel.username)
                    .font(.headline)
                Text(viewModel.roleName)
                    .font(.footnote)
                    .foregroundColor(Color(uiColor: .textSubtle))
            }
            // Error image
            Image(uiImage: .incorrectRoleError)
                .padding(.vertical, Layout.imageVerticalPadding)

            // Message
            Text(Localization.description)
                .multilineTextAlignment(.center)
                .bodyStyle()

            // Link button
            Button(Localization.learnMore) {
                showingLinkContent = true
            }
            .buttonStyle(LinkButtonStyle())
            .padding(.top, Layout.linkTopPadding)

            Spacer()
            Button(Localization.retryAction) {
                viewModel.reloadRoles()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .safariSheet(isPresented: $showingLinkContent, url: linkDestinationURL)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localization.cancelAction) {
                    onClose()
                }
                .buttonStyle(TextButtonStyle())
            }
        }

    }
}

extension AdminRoleRequiredView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let imageVerticalPadding: CGFloat = 16
        static let linkTopPadding: CGFloat = 16
    }
    enum Localization {
        static let description = NSLocalizedString(
            "It looks like your user role doesn't allow you to install Jetpack.\n" +
            "Please contact your administrator for help.",
            comment: "Message on the error modal when a user without admin role tries to install Jetpack"
        )
        static let learnMore = NSLocalizedString(
            "Learn more about roles and permissions",
            comment: "Link on the error modal when a user without admin role tries to install Jetpack"
        )
        static let retryAction = NSLocalizedString(
            "Retry",
            comment: "Button to reload user role on the error modal when a user without admin role tries to install Jetpack"
        )
        static let cancelAction = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the error modal when a user without admin role tries to install Jetpack"
        )
    }
}

struct AdminRoleRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        AdminRoleRequiredView(viewModel: .init()) {}
    }
}
