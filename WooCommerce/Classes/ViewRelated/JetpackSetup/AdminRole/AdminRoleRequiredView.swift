import SwiftUI

/// Hosting controller that wraps the `AdminRoleRequiredView`.
final class AdminRoleRequiredHostingController: UIHostingController<AdminRoleRequiredView> {
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    init(siteID: Int64, onClose: @escaping () -> Void, onSuccess: @escaping () -> Void) {
        super.init(rootView: AdminRoleRequiredView(viewModel: .init(siteID: siteID),
                                                   onClose: onClose,
                                                   onSuccess: onSuccess))
        rootView.onShowingNotice = { [weak self] message in
            self?.displayNotice(message: message)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }

    private func displayNotice(message: String) {
        let notice = Notice(title: message)
        noticePresenter.enqueue(notice: notice)
    }
}

/// Error view displayed when a user without admin role tries to install Jetpack.
struct AdminRoleRequiredView: View {
    /// Triggered when the user taps Cancel.
    let onClose: () -> Void
    /// Triggered when the user taps Retry and their role is updated with the admin role.
    let onSuccess: () -> Void
    /// Triggered when an error needs to be displayed.
    var onShowingNotice: (String) -> Void = { _ in }

    private let viewModel: AdminRoleRequiredViewModel

    /// Provides the URL destination when the link button is tapped
    private let linkDestinationURL = WooConstants.URLs.rolesAndPermissionsInfo.asURL()

    @State private var showingLinkContent = false
    @State private var isReloadingRoles = false

    init(viewModel: AdminRoleRequiredViewModel,
         onClose: @escaping () -> Void,
         onSuccess: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.onSuccess = onSuccess
    }

    var body: some View {
        ScrollableVStack(padding: Layout.horizontalPadding, spacing: 16) {
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
                Task { @MainActor in
                    isReloadingRoles = true
                    do {
                        let gotSufficientRole = try await viewModel.reloadRoles()
                        if gotSufficientRole {
                            onSuccess()
                        } else {
                            onShowingNotice(Localization.insufficientRoleMessage)
                        }
                    } catch {
                        onShowingNotice(Localization.retrieveErrorMessage)
                    }
                    isReloadingRoles = false
                }
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isReloadingRoles))
        }
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
        static let retrieveErrorMessage = NSLocalizedString(
            "Unable to retrieve user roles.",
            comment: "An error message shown when failing to retrieve information about user roles"
        )
        static let insufficientRoleMessage = NSLocalizedString(
            "You are not authorized to install Jetpack",
            comment: "An error message shown after the user retried checking their roles " +
            "but they still don't have enough permission to install Jetpack"
        )
    }
}

struct AdminRoleRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        AdminRoleRequiredView(viewModel: .init(siteID: 123),
                              onClose: {},
                              onSuccess: {})
    }
}
