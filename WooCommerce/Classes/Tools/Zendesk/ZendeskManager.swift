import Foundation
import ZendeskSDK
import ZendeskCoreSDK
import CoreTelephony
import WordPressAuthenticator
import SafariServices
import Yosemite


/// This class provides the functionality to communicate with Zendesk for Help Center and support ticket interaction,
/// as well as displaying views for the Help Center, new tickets, and ticket list.
///

/// This class is `@objc` because the `ZDKHelpCenterConversationsUIDelegate` inherits from `NSObject`.
/// This has to stay until Zendesk removes ObjC code from their framework.
///
@objc class ZendeskManager: NSObject {

    // MARK: - Public Properties
    //
    static let shared = ZendeskManager()
    private (set) var zendeskEnabled = false
    private var unreadNotificationsCount = 0

    var showSupportNotificationIndicator: Bool {
        return unreadNotificationsCount > 0
    }

    struct PushNotificationIdentifiers {
        static let key = "type"
        static let type = "zendesk"
    }

    // MARK: - Private Properties
    //
    private override init() {}
    private var sourceTag: WordPressSupportSourceTag?

    private var userName: String?
    private var userEmail: String?
    private var deviceID: String?
    private var haveUserIdentity = false
    private var alertNameField: UITextField?

    private var zdAppID: String?
    private var zdUrl: String?
    private var zdClientId: String?
    private var presentInController: UIViewController?

    private var appVersion: String {
        return Bundle.main.shortVersionString() ?? Constants.unknownValue
    }

    private var appLanguage: String {
        return Locale.preferredLanguages[0]
    }

    // MARK: - Public Methods
    //
    func initialize() {
        guard getZendeskCredentials() == true else {
            return
        }

        guard let appId = zdAppID,
            let url = zdUrl,
            let clientId = zdClientId else {
                DDLogInfo("Unable to set up Zendesk.")
                toggleZendesk(enabled: false)
                return
        }

        Zendesk.initialize(appId: appId, clientId: clientId, zendeskUrl: url)
        Support.initialize(withZendesk: Zendesk.instance)

        haveUserIdentity = getUserProfile()
        toggleZendesk(enabled: true)

        Theme.currentTheme.primaryColor = StyleManager.wooCommerceBrandColor

        observeZendeskNotifications()
    }

    /// Notification received or public method called,
    /// to signal that the default site may contain plan information.
    /// Uses `@objc` because this method is used in a `#selector()` call.
    @objc func updateSitePlan() {
        guard let siteID = StoresManager.shared.sessionManager.defaultSite?.siteID else {
            return
        }

        let action = AccountAction.synchronizeSitePlan(siteID: siteID) { (error) in
            if let error = error {
                DDLogError("⛔️ AccountAction: (Default Site) — Error synchronizing site plan: \(error)")
            }
        }

        StoresManager.shared.dispatch(action)
    }


    // MARK: - Show Zendesk Views

    // -TODO: in the future this should show the Zendesk Help Center.
    /// For now, link to the online FAQ
    ///
    func showHelpCenterIfPossible(from controller: UIViewController) {
        guard let faqURL = WooConstants.faqURL else {
            return
        }

        presentInController = controller
        WooAnalytics.shared.track(.supportBrowseOurFaqTapped)

        let safariViewController = SFSafariViewController(url: faqURL)
        safariViewController.modalPresentationStyle = .pageSheet

        controller.present(safariViewController, animated: true, completion: nil)
    }

    /// Displays the Zendesk New Request view from the given controller, for users to submit new tickets.
    ///
    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {

        presentInController = controller

        createIdentity { success in
            guard success else {
                return
            }

            self.sourceTag = sourceTag
            WooAnalytics.shared.track(.supportNewRequestViewed)

            let newRequestConfig = self.createRequest()
            let newRequestController = RequestUi.buildRequestUi(with: [newRequestConfig])
            self.showZendeskView(newRequestController)
        }
    }

    /// Displays the Zendesk Request List view from the given controller, allowing user to access their tickets.
    ///
    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {

        presentInController = controller

        createIdentity { success in
            guard success else {
                return
            }

            self.sourceTag = sourceTag
            WooAnalytics.shared.track(.supportTicketListViewed)

            let requestConfig = self.createRequest()
            let requestListController = RequestUi.buildRequestList(with: [requestConfig])
            self.showZendeskView(requestListController)
        }
    }

    /// Displays an alert allowing the user to change their Support email address.
    ///
    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping (Bool) -> Void) {
        WooAnalytics.shared.track(.supportIdentityFormViewed)
        presentInController = controller

        getUserInformationAndShowPrompt(withName: false) { success in
            completion(success)
        }
    }


    // MARK: - Helpers

    /// Returns the user's Support email address.
    ///
    func userSupportEmail() -> String? {
        let _ = getUserProfile()
        return userEmail
    }

    /// Returns the tags for the ZD ticket field
    ///
    func getTags() -> [String] {

        /// Start with default tags.
        /// Tags are used for refining and filtering tickets so they display in the web portal, under "Lovely Views".
        /// The SDK tag is used in a trigger and displays tickets in Woo > Mobile Apps New.
        var tags = [Constants.platformTag,
                    Constants.sdkTag,
                    Constants.jetpackTag]

        /// Determine if the account is a wp.com account.
        ///
        guard let site = StoresManager.shared.sessionManager.defaultSite else {
            return tags
        }

        /// Determine this is a wp.com store.
        /// No tag if self-hosted.
        if site.isWordPressStore == true {
            tags.append(Constants.wpComTag)
        }

        /// Add the site plan.
        ///
        if site.plan.isEmpty == false {
            tags.append(site.plan)
        }

        /// Add source tag.
        ///
        if let sourceTagOrigin = sourceTag?.origin, sourceTagOrigin.isEmpty == false {
            tags.append(sourceTagOrigin)
        }

        return tags
    }
}

// MARK: - Private Extension
//
private extension ZendeskManager {

    func getZendeskCredentials() -> Bool {
        let appId = ApiCredentials.zendeskAppId
        let url = ApiCredentials.zendeskUrl
        let clientId = ApiCredentials.zendeskClientId

        guard !appId.isEmpty, !url.isEmpty, !clientId.isEmpty else {
            DDLogInfo("Unable to get Zendesk credentials.")
            toggleZendesk(enabled: false)
            return false
        }

        zdAppID = appId
        zdUrl = url
        zdClientId = clientId
        return true
    }

    func toggleZendesk(enabled: Bool) {
        zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    func createIdentity(completion: @escaping (Bool) -> Void) {

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

        getUserInformationAndShowPrompt(withName: true) { success in
            completion(success)
        }
    }

    func getUserInformationAndShowPrompt(withName: Bool, completion: @escaping (Bool) -> Void) {
        getUserInformationIfAvailable()
        promptUserForInformation(withName: withName) { success in
            guard success else {
                DDLogInfo("No user information to create Zendesk identity with.")
                completion(false)
                return
            }

            self.createZendeskIdentity { success in
                guard success else {
                    DDLogInfo("Creating Zendesk identity failed.")
                    completion(false)
                    return
                }
                DDLogDebug("Using information from prompt for Zendesk identity.")
                self.haveUserIdentity = true
                completion(true)
                return
            }
        }
    }

    func getUserInformationIfAvailable() {
        userEmail = StoresManager.shared.sessionManager.defaultAccount?.email
        userName = StoresManager.shared.sessionManager.defaultAccount?.username

        if let displayName = StoresManager.shared.sessionManager.defaultAccount?.displayName,
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


    // MARK: - Request Controller Configuration
    //

    /// Important: Any time a new request controller is created, these configurations should be attached.
    /// Without it, the tickets won't appear in the correct view(s) in the web portal and they won't contain all the metadata needed to solve a ticket.
    func createRequest() -> RequestUiConfiguration {

        let requestConfig = RequestUiConfiguration()

        // Set Zendesk ticket form to use
        requestConfig.ticketFormID = TicketFieldIDs.form as NSNumber

        // Set form field values
        var ticketFields = [ZDKCustomField]()
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appVersion as NSNumber, andValue: appVersion))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.deviceFreeSpace as NSNumber, andValue: getDeviceFreeSpace()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.networkInformation as NSNumber, andValue: getNetworkInformation()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.logs as NSNumber, andValue: getLogFile()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.currentSite as NSNumber, andValue: getCurrentSiteDescription()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.sourcePlatform as NSNumber, andValue: Constants.sourcePlatform))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appLanguage as NSNumber, andValue: appLanguage))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.subcategory as NSNumber, andValue: Constants.subcategory))
        requestConfig.fields = ticketFields

        // Set tags
        requestConfig.tags = getTags()

        // Set the ticket subject
        requestConfig.subject = Constants.ticketSubject

        // No extra config needed to attach an image. Hooray!

        return requestConfig
    }

    // MARK: - View
    //
    func showZendeskView(_ zendeskView: UIViewController) {
        guard let presentInController = presentInController else {
            return
        }

        // If the controller is a UIViewController, set the modal display for iPad.
        if !presentInController.isKind(of: UINavigationController.self) && UIDevice.current.userInterfaceIdiom == .pad {
            let navController = UINavigationController(rootViewController: zendeskView)
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .crossDissolve
            presentInController.present(navController, animated: true)
            return
        }

        if let navController = presentInController as? UINavigationController {
            navController.pushViewController(zendeskView, animated: true)
        }
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


    // MARK: - Data Helpers
    //
    func getDeviceFreeSpace() -> String {

        guard let resourceValues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
            let capacityBytes = resourceValues.volumeAvailableCapacity else {
                return Constants.unknownValue
        }

        // format string using human readable units. ex: 1.5 GB
        // Since ByteCountFormatter.string translates the string and has no locale setting,
        // do the byte conversion manually so the Free Space is in English.
        let sizeAbbreviations = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        var sizeAbbreviationsIndex = 0
        var capacity = Double(capacityBytes)

        while capacity > 1024 {
            capacity /= 1024
            sizeAbbreviationsIndex += 1
        }

        let formattedCapacity = String(format: "%4.2f", capacity)
        let sizeAbbreviation = sizeAbbreviations[sizeAbbreviationsIndex]
        return "\(formattedCapacity) \(sizeAbbreviation)"
    }

    func getLogFile() -> String {

        guard let logFileInformation = AppDelegate.shared.fileLogger.logFileManager.sortedLogFileInfos.first,
            let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
            let logText = String(data: logData, encoding: .utf8) else {
                return ""
        }

        return logText
    }

    func getCurrentSiteDescription() -> String {
        guard let site = StoresManager.shared.sessionManager.defaultSite else {
            return String()
        }

        let url = site.url
        return "\(url) (\(site.description))"
    }


    func getNetworkInformation() -> String {

        var networkInformation = [String]()

        let reachibilityStatus = ZDKReachability.forInternetConnection().currentReachabilityStatus()

        let networkType: String = {
            switch reachibilityStatus {
            case .reachableViaWiFi:
                return Constants.networkWiFi
            case .reachableViaWWAN:
                return Constants.networkWWAN
            default:
                return Constants.unknownValue
            }
        }()

        let networkCarrier = CTTelephonyNetworkInfo().subscriberCellularProvider
        let carrierName = networkCarrier?.carrierName ?? Constants.unknownValue
        let carrierCountryCode = networkCarrier?.isoCountryCode ?? Constants.unknownValue

        networkInformation.append("\(Constants.networkTypeLabel) \(networkType)")
        networkInformation.append("\(Constants.networkCarrierLabel) \(carrierName)")
        networkInformation.append("\(Constants.networkCountryCodeLabel) \(carrierCountryCode)")

        return networkInformation.joined(separator: "\n")
    }


    // MARK: - User Information Prompt
    //
    func promptUserForInformation(withName: Bool, completion: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .alert)

        let alertMessage = withName ? LocalizedText.alertMessageWithName : LocalizedText.alertMessage
        alertController.setValue(NSAttributedString(string: alertMessage, attributes: [.font: UIFont.caption1]),
                                 forKey: "attributedMessage")

        // Cancel Action
        alertController.addCancelActionWithTitle(LocalizedText.alertCancel) { (_) in
            completion(false)
            return
        }

        // Submit Action
        let submitAction = alertController.addDefaultActionWithTitle(LocalizedText.alertSubmit) { [weak alertController] (_) in
            guard let email = alertController?.textFields?.first?.text else {
                completion(false)
                return
            }

            self.userEmail = email

            if withName {
                self.userName = alertController?.textFields?.last?.text
            }

            self.saveUserProfile()
            completion(true)
            return
        }

        // Enable Submit based on email validity.
        let email = userEmail ?? ""
        submitAction.isEnabled = EmailFormatValidator.validate(string: email)

        // Make Submit button bold.
        alertController.preferredAction = submitAction

        // Email Text Field
        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.emailPlaceholder
            textField.text = self.userEmail

            textField.addTarget(self,
                                action: #selector(self.emailTextFieldDidChange),
                                for: UIControl.Event.editingChanged)
        })

        // Name Text Field
        if withName {
            alertController.addTextField { textField in
                textField.clearButtonMode = .always
                textField.placeholder = LocalizedText.namePlaceholder
                textField.text = self.userName
                textField.delegate = ZendeskManager.shared
                ZendeskManager.shared.alertNameField = textField
            }
        }

        // Show alert
        presentInController?.present(alertController, animated: true, completion: nil)
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

        // Generate Name, using the same format as Signup.

        // step 1: lower case
        let email = rawEmail.lowercased()
        // step 2: remove the @ and everything after
        let localPart = email.split(separator: "@")[0]
        // step 3: remove all non-alpha characters
        let localCleaned = localPart.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased.capitalized

        return autoDisplayName
    }

    // MARK: - Zendesk Notifications
    //
    func observeZendeskNotifications() {
        // Ticket Attachments
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_UploadAttachmentSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_UploadAttachmentError), object: nil)

        // New Ticket Creation
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestSubmissionSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestSubmissionError), object: nil)

        // Ticket Reply
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentSubmissionSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentSubmissionError), object: nil)

        // View Ticket List
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestsError), object: nil)

        // View Individual Ticket
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentListSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentListError), object: nil)

        // Help Center
        NotificationCenter.default.addObserver(self, selector: #selector(zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZD_HC_SearchSuccess), object: nil)
    }

    /// Uses `@objc` because it's referenced in an ObjC `#selector` call
    ///
    @objc func zendeskNotification(_ notification: Foundation.Notification) {
        switch notification.name.rawValue {
        case ZDKAPI_RequestSubmissionSuccess:
            WooAnalytics.shared.track(.supportNewRequestCreated)
        case ZDKAPI_RequestSubmissionError:
            WooAnalytics.shared.track(.supportNewRequestFailed)
        case ZDKAPI_UploadAttachmentSuccess:
            WooAnalytics.shared.track(.supportNewRequestFileAttached)
        case ZDKAPI_UploadAttachmentError:
            WooAnalytics.shared.track(.supportNewRequestFileAttachmentFailed)
        case ZDKAPI_CommentSubmissionSuccess:
            WooAnalytics.shared.track(.supportTicketUserReplied)
        case ZDKAPI_CommentSubmissionError:
            WooAnalytics.shared.track(.supportTicketUserReplyFailed)
        case ZDKAPI_RequestsError:
            WooAnalytics.shared.track(.supportTicketListViewFailed)
        case ZDKAPI_CommentListSuccess:
            WooAnalytics.shared.track(.supportTicketUserViewed)
        case ZDKAPI_CommentListError:
            WooAnalytics.shared.track(.supportTicketViewFailed)
        case ZD_HC_SearchSuccess:
            WooAnalytics.shared.track(.supportHelpCenterUserSearched)
        default:
            break
        }
    }


    // MARK: - Observe Notifications
    //
    func observeNotifications() {
        // Default Site Plan Changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateSitePlan), name: NSNotification.Name.StoresManagerDidUpdateDefaultSite, object: nil)
    }


    // MARK: - Constants
    //
    struct Constants {
        static let unknownValue = "unknown"
        static let noValue = "none"
        static let mobileCategoryID: UInt64 = 360000041586
        static let articleLabel = "iOS"
        static let platformTag = "iOS"
        static let sdkTag = "woo-mobile-sdk"
        static let ticketSubject = NSLocalizedString("WooCommerce for iOS Support", comment: "Subject of new Zendesk ticket.")
        static let blogSeperator = "\n----------\n"
        static let jetpackTag = "jetpack"
        static let wpComTag = "wpcom"
        static let networkWiFi = "WiFi"
        static let networkWWAN = "Mobile"
        static let networkTypeLabel = "Network Type:"
        static let networkCarrierLabel = "Carrier:"
        static let networkCountryCodeLabel = "Country Code:"
        static let zendeskProfileUDKey = "wc_zendesk_profile"
        static let profileEmailKey = "email"
        static let profileNameKey = "name"
        static let nameFieldCharacterLimit = 50
        static let sourcePlatform = "mobile_-_woo_ios"
        static let subcategory = "WooCommerce Mobile Apps"
    }

    // Zendesk expects these as NSNumber. However, they are defined as UInt64 to satisfy 32-bit devices (ex: iPhone 5).
    // Which means they then have to be converted to NSNumber when sending to Zendesk.
    struct TicketFieldIDs {
        static let form: UInt64 = 360000010286
        static let appVersion: UInt64 = 360000086866
        static let allBlogs: UInt64 = 360000087183
        static let deviceFreeSpace: UInt64 = 360000089123
        static let networkInformation: UInt64 = 360000086966
        static let logs: UInt64 = 22871957
        static let currentSite: UInt64 = 360000103103
        static let sourcePlatform: UInt64 = 360009311651
        static let appLanguage: UInt64 = 360008583691
        static let subcategory: UInt64 = 25176023
    }

    struct LocalizedText {
        static let alertMessageWithName = NSLocalizedString("To continue please enter your email address and name.", comment: "Instructions for alert asking for email and name.")
        static let alertMessage = NSLocalizedString("Please enter your email address.", comment: "Instructions for alert asking for email.")
        static let alertSubmit = NSLocalizedString("OK", comment: "Submit button on prompt for user information.")
        static let alertCancel = NSLocalizedString("Cancel", comment: "Cancel prompt for user information.")
        static let emailPlaceholder = NSLocalizedString("Email", comment: "Email address text field placeholder")
        static let namePlaceholder = NSLocalizedString("Name", comment: "Name text field placeholder")
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
