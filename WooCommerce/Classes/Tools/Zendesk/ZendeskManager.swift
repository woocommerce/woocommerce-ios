import Foundation
#if !targetEnvironment(macCatalyst)
import SupportSDK
import ZendeskCoreSDK
import CommonUISDK // Zendesk UI SDK
#endif
import WordPressShared
import SafariServices
import Yosemite
import Experiments

/// Defines methods for showing Zendesk UI.
///
/// This is primarily used for testability. Not all methods in `ZendeskManager` are defined but
/// feel free to add them when needed.
///
protocol ZendeskManagerProtocol {
    typealias onUserInformationCompletion = (_ success: Bool, _ email: String?) -> Void

    /// Creates a Zendesk Identity to be able to submit support request tickets.
    /// Uses the provided `ViewController` to present an alert for requesting email address when required.
    ///
    func createIdentity(presentIn viewController: UIViewController, completion: @escaping (Bool) -> Void)

    /// Creates a support request using the API-Providers SDK.
    ///
    func createSupportRequest(formID: Int64,
                              customFields: [Int64: String],
                              tags: [String],
                              subject: String,
                              description: String,
                              onCompletion: @escaping (Result<Void, Error>) -> Void)

    var zendeskEnabled: Bool { get }
    func userSupportEmail() -> String?
    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping onUserInformationCompletion)
    func initialize()
    func reset()
}

struct NoZendeskManager: ZendeskManagerProtocol {
    func createIdentity(presentIn viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        // no-op
    }

    func createSupportRequest(formID: Int64,
                              customFields: [Int64: String],
                              tags: [String],
                              subject: String,
                              description: String,
                              onCompletion: @escaping (Result<Void, Error>) -> Void) {
        // no-op
    }

    var zendeskEnabled = false

    func userSupportEmail() -> String? {
        return nil
    }

    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping onUserInformationCompletion) {
        // no-op
    }

    func initialize() {
        // no-op
    }

    func reset() {
        // no-op
    }
}

struct ZendeskProvider {
    /// Shared Instance
    ///
    #if !targetEnvironment(macCatalyst)
    static let shared: ZendeskManagerProtocol = ZendeskManager()
    #else
    static let shared: ZendeskManagerProtocol = NoZendeskManager()
    #endif
}


/// This class provides the functionality to communicate with Zendesk for Help Center and support ticket interaction,
/// as well as displaying views for the Help Center, new tickets, and ticket list.
///
#if !targetEnvironment(macCatalyst)
final class ZendeskManager: NSObject, ZendeskManagerProtocol {
    /// Indicates if Zendesk is Enabled (or not)
    ///
    private (set) var zendeskEnabled = false {
        didSet {
            DDLogInfo("Zendesk Enabled: \(zendeskEnabled)")
        }
    }

    // MARK: - Private Properties
    //
    private var userName: String?
    private var userEmail: String?
    private var haveUserIdentity = false
    private var alertNameField: UITextField?

    private weak var presentInController: UIViewController?

    // MARK: - Public Methods


    /// Sets up the Zendesk Manager instance
    ///
    func initialize() {
        guard zendeskEnabled == false else {
            DDLogError("☎️ Zendesk was already Initialized!")
            return
        }

        Zendesk.initialize(appId: ApiCredentials.zendeskAppId,
                           clientId: ApiCredentials.zendeskClientId,
                           zendeskUrl: ApiCredentials.zendeskUrl)
        Support.initialize(withZendesk: Zendesk.instance)
        CommonTheme.currentTheme.primaryColor = UIColor.primary

        haveUserIdentity = getUserProfile()
        zendeskEnabled = true
    }

    /// Deletes all known user default keys
    ///
    func reset() {
        removeUserProfile()
    }

    /// Creates a Zendesk Identity to be able to submit support request tickets.
    /// Uses the provided `ViewController` to present an alert for requesting email address when required.
    ///
    func createIdentity(presentIn viewController: UIViewController, completion: @escaping (Bool) -> Void) {

        // If we already have an identity, do nothing.
        guard haveUserIdentity == false else {
            DDLogDebug("Using existing Zendesk identity: \(userEmail ?? ""), \(userName ?? "")")
            completion(true)
            return
        }

        /*
         1. Attempt to get user information from User Defaults.
         2. If we don't have the user's information yet, attempt to get it from the account/site.
         3. Prompt the user for email & name, pre-populating with user information obtained in step 1.
         4. Create Zendesk identity with user information.
         */

        if getUserProfile() {
            createZendeskIdentity { success in
                guard success else {
                    DDLogInfo("Creating Zendesk identity failed.")
                    completion(false)
                    return
                }
                DDLogDebug("Using User Defaults for Zendesk identity.")
                self.haveUserIdentity = true
                completion(true)
                return
            }
        }

        getUserInformationAndShowPrompt(withName: true, from: viewController) { (success, _) in
            completion(success)
        }
    }

    /// Creates a support request using the API-Providers SDK.
    ///
    func createSupportRequest(formID: Int64,
                              customFields: [Int64: String],
                              tags: [String],
                              subject: String,
                              description: String,
                              onCompletion: @escaping (Result<Void, Error>) -> Void) {

        let requestProvider = ZDKRequestProvider()
        let request = createAPIRequest(formID: formID, customFields: customFields, tags: tags, subject: subject, description: description)
        requestProvider.createRequest(request) { _, error in
            // `requestProvider.createRequest` invokes it's completion block on a background thread when the request creation fails.
            // Lets make sure we always dispatch the completion block on the main queue.
            DispatchQueue.main.async {
                if let error {
                    return onCompletion(.failure(error))
                }
                onCompletion(.success(()))
            }
        }
    }

    /// Displays an alert allowing the user to change their Support email address.
    ///
    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping onUserInformationCompletion) {
        ServiceLocator.analytics.track(.supportIdentityFormViewed)
        presentInController = controller

        // If the user hasn't already set a username, go ahead and ask for that too.
        var withName = true
        if let name = userName, !name.isEmpty {
            withName = false
        }

        getUserInformationAndShowPrompt(withName: withName, from: controller) { (success, email) in
            completion(success, email)
        }
    }


    // MARK: - Helpers

    /// Returns the user's Support email address.
    ///
    func userSupportEmail() -> String? {
        let _ = getUserProfile()
        return userEmail
    }
}

// MARK: - Private Extension
//
private extension ZendeskManager {

    func getUserInformationAndShowPrompt(withName: Bool, from viewController: UIViewController, completion: @escaping onUserInformationCompletion) {
        presentInController = viewController
        getUserInformationIfAvailable()
        promptUserForInformation(withName: withName, from: viewController) { (success, email) in
            guard success else {
                DDLogInfo("No user information to create Zendesk identity with.")
                completion(false, nil)
                return
            }

            self.createZendeskIdentity { success in
                guard success else {
                    DDLogInfo("Creating Zendesk identity failed.")
                    completion(false, nil)
                    return
                }

                DDLogDebug("Using information from prompt for Zendesk identity.")
                self.haveUserIdentity = true
                completion(true, email)
                return
            }
        }
    }

    func getUserInformationIfAvailable() {
        userEmail = ServiceLocator.stores.sessionManager.defaultAccount?.email
        userName = ServiceLocator.stores.sessionManager.defaultAccount?.username

        if let displayName = ServiceLocator.stores.sessionManager.defaultAccount?.displayName,
            !displayName.isEmpty {
            userName = displayName
        }
    }

    func createZendeskIdentity(completion: @escaping (Bool) -> Void) {

        guard let userEmail = userEmail else {
            DDLogInfo("No user email to create Zendesk identity with.")
            let identity = Identity.createAnonymous()
            Zendesk.instance?.setIdentity(identity)
            completion(false)

            return
        }

        let zendeskIdentity = Identity.createAnonymous(name: userName, email: userEmail)
        Zendesk.instance?.setIdentity(zendeskIdentity)

        DDLogDebug("Zendesk identity created with email '\(userEmail)' and name '\(userName ?? "")'.")
        completion(true)
    }


    /// Creates a Zendesk Request to be consumed by a Request Provider.
    ///
    func createAPIRequest(formID: Int64, customFields: [Int64: String], tags: [String], subject: String, description: String) -> ZDKCreateRequest {
        let request = ZDKCreateRequest()
        request.ticketFormId = formID as NSNumber
        request.customFields = customFields.map { CustomField(fieldId: $0, value: $1) }
        request.tags = tags
        request.subject = subject
        request.requestDescription = description
        return request
    }

    // MARK: - User Defaults
    //
    func saveUserProfile() {
        var userProfile = [String: String]()
        userProfile[Constants.profileEmailKey] = userEmail
        userProfile[Constants.profileNameKey] = userName
        DDLogDebug("Zendesk - saving profile to User Defaults: \(userProfile)")
        UserDefaults.standard.set(userProfile, forKey: Constants.zendeskProfileUDKey)
        UserDefaults.standard.synchronize()
    }

    func getUserProfile() -> Bool {
        guard let userProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskProfileUDKey) else {
            return false
        }
        DDLogDebug("Zendesk - read profile from User Defaults: \(userProfile)")
        userEmail = userProfile.valueAsString(forKey: Constants.profileEmailKey)
        userName = userProfile.valueAsString(forKey: Constants.profileNameKey)
        return true
    }

    func removeUserProfile() {
        UserDefaults.standard.removeObject(forKey: Constants.zendeskProfileUDKey)
    }

    // MARK: - User Information Prompt
    //
    func promptUserForInformation(withName: Bool, from viewController: UIViewController, completion: @escaping onUserInformationCompletion) {

        let alertMessage = withName ? LocalizedText.alertMessageWithName : LocalizedText.alertMessage
        let alertController = UIAlertController(title: nil, message: alertMessage, preferredStyle: .alert)

        // Cancel Action
        alertController.addCancelActionWithTitle(LocalizedText.alertCancel) { _ in
            completion(false, nil)
            return
        }

        // Submit Action
        let submitAction = alertController.addDefaultActionWithTitle(LocalizedText.alertSubmit) { [weak alertController] _ in
            guard let email = alertController?.textFields?.first?.text else {
                completion(false, nil)
                return
            }

            self.userEmail = email

            if withName {
                self.userName = alertController?.textFields?.last?.text
            }

            self.saveUserProfile()
            completion(true, email)
            return
        }

        // Enable Submit based on email validity.
        let email = userEmail ?? ""
        submitAction.isEnabled = EmailFormatValidator.validate(string: email)

        // Make Submit button bold.
        alertController.preferredAction = submitAction

        // Email Text Field
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.keyboardType = .emailAddress
            textField.placeholder = LocalizedText.emailPlaceholder
            textField.text = self.userEmail

            textField.addTarget(self,
                                action: #selector(self.emailTextFieldDidChange),
                                for: UIControl.Event.editingChanged)
        }

        // Name Text Field
        if withName {
            alertController.addTextField { [weak self] textField in
                guard let self = self else { return }
                textField.clearButtonMode = .always
                textField.placeholder = LocalizedText.namePlaceholder
                textField.text = self.userName
                textField.delegate = self
                self.alertNameField = textField
            }
        }

        // Show alert
        viewController.present(alertController, animated: true, completion: nil)
    }

    /// Uses `@objc` because this method is used in a `#selector()` call
    ///
    @objc func emailTextFieldDidChange(_ textField: UITextField) {
        guard let alertController = presentInController?.presentedViewController as? UIAlertController,
            let email = alertController.textFields?.first?.text,
            let submitAction = alertController.actions.last else {
                return
        }

        submitAction.isEnabled = EmailFormatValidator.validate(string: email)
        updateNameFieldForEmail(email)
    }

    func updateNameFieldForEmail(_ email: String) {
        guard let alertController = presentInController?.presentedViewController as? UIAlertController,
            let totalTextFields = alertController.textFields?.count,
            totalTextFields > 1,
            let nameField = alertController.textFields?.last else {
                return
        }

        guard !email.isEmpty else {
            return
        }

        // If we don't already have the user's name, generate it from the email.
        if userName == nil {
            nameField.text = generateDisplayName(from: email)
        }
    }

    func generateDisplayName(from rawEmail: String) -> String {
        guard rawEmail.isEmpty == false else {
            return ""
        }

        // Generate Name, using the same format as Signup.

        // step 1: lower case
        let email = rawEmail.lowercased()
        // step 2: remove the @ and everything after
        let localPart = email.split(separator: "@")[safe: 0]
        // step 3: remove all non-alpha characters
        let localCleaned = localPart?.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned?.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased?.capitalized

        return autoDisplayName ?? ""
    }
}


// MARK: - Nested Types
//
private extension ZendeskManager {

    // MARK: - Constants
    //
    struct Constants {
        static let profileEmailKey = "email"
        static let profileNameKey = "name"
        static let nameFieldCharacterLimit = 50
        static let zendeskProfileUDKey = "wc_zendesk_profile"
    }

    struct LocalizedText {
        static let alertMessageWithName = NSLocalizedString(
            "Please enter your email address and username:",
            comment: "Instructions for alert asking for email and name."
        )
        static let alertMessage = NSLocalizedString(
            "Please enter your email address:",
            comment: "Instructions for alert asking for email."
        )
        static let alertSubmit = NSLocalizedString(
            "OK",
            comment: "Submit button on prompt for user information."
        )
        static let alertCancel = NSLocalizedString(
            "Cancel",
            comment: "Cancel prompt for user information."
        )
        static let emailPlaceholder = NSLocalizedString(
            "Email",
            comment: "Email address text field placeholder"
        )
        static let namePlaceholder = NSLocalizedString(
            "Name",
            comment: "Name text field placeholder"
        )
    }
}

// MARK: - UITextFieldDelegate
//
extension ZendeskManager: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == alertNameField,
            let text = textField.text else {
                return true
        }

        let newLength = text.count + string.count - range.length
        return newLength <= Constants.nameFieldCharacterLimit
    }
}
#endif
