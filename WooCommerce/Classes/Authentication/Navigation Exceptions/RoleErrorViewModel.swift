import Foundation
import UIKit

final class RoleErrorViewModel {
    private let siteID: Int64
    private let roleEligibilityUseCase: RoleEligibilityUseCaseProtocol

    /// Provides the content for title label.
    private(set) var titleText: String

    /// Provides the content for subtitle label.
    private(set) var subtitleText: String = ""

    /// An illustration accompanying the error.
    /// This is intended as a computed property to adjust to runtime color appearance changes.
    var image: UIImage {
        .incorrectRoleError
    }

    /// A closure that will be called when the current user is eligible after retrying the role check.
    var onSuccess: (() -> Void)?

    /// A closure that will be called when the user selected the option to try with another account.
    var onDeauthenticationRequest: (() -> Void)?

    /// Extended description of the error.
    let descriptionText: String = .errorMessageText

    /// Provides the title for an auxiliary button
    let auxiliaryButtonTitle: String = .linkButtonTitle

    /// Provides the title for a primary action button
    let primaryButtonTitle: String = .primaryButtonTitle

    /// Provides the title for a secondary action button
    let secondaryButtonTitle: String = .secondaryButtonTitle

    /// Provides the title for the help navigation bar button
    let helpBarButtonTitle: String = .helpBarButtonItemTitle

    /// Provides the URL destination when the link button is tapped
    private let linkDestinationURL = WooConstants.URLs.rolesAndPermissionsInfo.asURL()

    /// An object capable of executing display-related tasks based on updates
    /// from the view model.
    weak var output: RoleErrorOutput?

    // MARK: Lifecycle

    init(siteID: Int64, title: String, subtitle: String, useCase: RoleEligibilityUseCaseProtocol = RoleEligibilityUseCase()) {
        self.siteID = siteID
        self.titleText = title
        self.subtitleText = subtitle
        self.roleEligibilityUseCase = useCase
    }

    /// When the primary button is tapped, the role check request will be retried.
    /// If the request is successful, the stored error info will be cleared and `onSuccess` will be called.
    /// Otherwise, the view will be refreshed and a notice will be shown.
    func didTapPrimaryButton() {
        roleEligibilityUseCase.checkEligibility(for: siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.onSuccess?()
                break

            case .failure(let error):
                // update the view and show notice that the user's role is still not eligible.
                if case let RoleEligibilityError.insufficientRole(errorInfo) = error {
                    self.titleText = errorInfo.name
                    self.subtitleText = errorInfo.humanizedRoles
                    self.output?.refreshTitleLabels()
                    self.output?.displayNotice(message: .insufficientRolesErrorMessage)
                    break
                }

                // otherwise, show notice that the role check failed for some reason.
                self.output?.displayNotice(message: .retrieveErrorMessage)
            }
        }
    }

    func didTapSecondaryButton() {
        onDeauthenticationRequest?()
    }

    func didTapAuxiliaryButton() {
        output?.displayWebContent(for: linkDestinationURL)
    }
}

// MARK: - Localization

private extension String {
    static let errorMessageText = NSLocalizedString("This app supports only Administrator and Shop Manager user roles. "
                                                        + "Please contact your store owner to upgrade your role.",
                                                    comment: "Message explaining more detail on why the user's role is incorrect.")

    static let linkButtonTitle = NSLocalizedString("Learn more about roles and permissions",
                                                   comment: "Link that points the user to learn more about roles. Clicking will open a web page."
                                                    + "Presented when the user has tries to switch to a store with incorrect permissions.")

    static let primaryButtonTitle = NSLocalizedString("Retry",
                                                      comment: "Action button that will recheck whether user has sufficient permissions to manage the store."
                                                        + "Presented when the user tries to switch to a store with incorrect permissions.")

    static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                        comment: "Action button that will restart the login flow."
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

    static let helpBarButtonItemTitle = NSLocalizedString("Help", comment: "Help button")

    static let insufficientRolesErrorMessage = NSLocalizedString("You are not authorized to access this store.",
                                                                 comment: "An error message shown after the user retried checking their roles,"
                                                                    + "but they still don't have enough permission to access the store through the app.")

    static let retrieveErrorMessage = NSLocalizedString("Unable to retrieve user roles.",
                                                        comment: "An error message shown when failing to retrieve information about user roles, "
                                                            + "before letting the user in to manage the store.")
}
