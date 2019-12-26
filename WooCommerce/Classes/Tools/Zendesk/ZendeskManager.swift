import Foundation
import ZendeskSDK
import ZendeskCoreSDK
import CommonUISDK // Zendesk UI SDK
import WordPressShared
import CoreTelephony
import SafariServices
import Yosemite


extension NSNotification.Name {
    static let ZDPNReceived = NSNotification.Name(rawValue: "ZDPNReceived")
    static let ZDPNCleared = NSNotification.Name(rawValue: "ZDPNCleared")
}


/// This class provides the functionality to communicate with Zendesk for Help Center and support ticket interaction,
/// as well as displaying views for the Help Center, new tickets, and ticket list.
///
class ZendeskManager: NSObject {

    /// Shared Instance
    ///
    static let shared = ZendeskManager()

    typealias onUserInformationCompletion = (_ success: Bool, _ email: String?) -> Void

    /// Indicates if Zendesk is Enabled (or not)
    ///
    private (set) var zendeskEnabled = false {
        didSet {
            DDLogInfo("Zendesk Enabled: \(zendeskEnabled)")
        }
    }

    private var unreadNotificationsCount = 0

    var showSupportNotificationIndicator: Bool {
        return unreadNotificationsCount > 0
    }


    // MARK: - Private Properties
    //
    private var deviceToken: String?
    private var userName: String?
    private var userEmail: String?
    private var haveUserIdentity = false
    private var alertNameField: UITextField?

    private weak var presentInController: UIViewController?

    /// Returns a ZendeskPushProvider Instance (If Possible)
    ///
    private var zendeskPushProvider: ZDKPushProvider? {
        guard let zendesk = Zendesk.instance else {
            return nil
        }

        return ZDKPushProvider(zendesk: zendesk)
    }


    /// Designated Initialier
    ///
    private override init() {
        super.init()
        observeZendeskNotifications()
    }


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
        SupportUI.initialize(withZendesk: Zendesk.instance)
        CommonTheme.currentTheme.primaryColor = UIColor.primary

        haveUserIdentity = getUserProfile()
        zendeskEnabled = true
    }

    /// Deletes all known user default keys
    ///
    func reset() {
        removeUserProfile()
        removeUnreadCount()
    }


    // MARK: - Show Zendesk Views
    //
    // -TODO: in the future this should show the Zendesk Help Center.
    /// For now, link to the online help documentation
    ///
    func showHelpCenter(from controller: UIViewController) {
        let safariViewController = SFSafariViewController(url: WooConstants.helpCenterURL)
        safariViewController.modalPresentationStyle = .pageSheet
        controller.present(safariViewController, animated: true, completion: nil)

        ServiceLocator.analytics.track(.supportHelpCenterViewed)
    }

    /// Displays the Zendesk New Request view from the given controller, for users to submit new tickets.
    ///
    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: String? = nil) {

        createIdentity(presentIn: controller) { success in
            guard success else {
                return
            }

            ServiceLocator.analytics.track(.supportNewRequestViewed)

            let newRequestConfig = self.createRequest(supportSourceTag: sourceTag)
            let newRequestController = RequestUi.buildRequestUi(with: [newRequestConfig])
            self.showZendeskView(newRequestController, from: controller)
        }
    }

    /// Displays the Zendesk Request List view from the given controller, allowing user to access their tickets.
    ///
    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: String? = nil) {

        createIdentity(presentIn: controller) { success in
            guard success else {
                return
            }

            ServiceLocator.analytics.track(.supportTicketListViewed)

            let requestConfig = self.createRequest(supportSourceTag: sourceTag)
            let requestListController = RequestUi.buildRequestList(with: [requestConfig])
            self.showZendeskView(requestListController, from: controller)
        }
    }

    /// Displays a single ticket's view if possible.
    ///
    func showSingleTicketViewIfPossible(for requestId: String, from navController: UINavigationController) {
        let requestConfig = self.createRequest(supportSourceTag: nil)
        let requestController = RequestUi.buildRequestUi(requestId: requestId, configurations: [requestConfig])

        showZendeskView(requestController, from: navController)
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

    /// Returns the tags for the ZD ticket field.
    /// Tags are used for refining and filtering tickets so they display in the web portal, under "Lovely Views".
    /// The SDK tag is used in a trigger and displays tickets in Woo > Mobile Apps New.
    ///
    func getTags(supportSourceTag: String?) -> [String] {
        var tags = [Constants.platformTag, Constants.sdkTag, Constants.jetpackTag]
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return tags
        }

        if site.isWordPressStore == true {
            tags.append(Constants.wpComTag)
        }

        if site.plan.isEmpty == false {
            tags.append(site.plan)
        }

        if let sourceTagOrigin = supportSourceTag, sourceTagOrigin.isEmpty == false {
            tags.append(sourceTagOrigin)
        }

        return tags
    }
}

// MARK: - Push Notifications
//
extension ZendeskManager {
    /// Registers the last known DeviceToken in the Zendesk Backend (if any).
    ///
    func registerDeviceTokenIfNeeded() {
        guard let deviceToken = deviceToken else {
            DDLogError("☎️ [Zendesk] Missing Device Token!")
            return
        }

        registerDeviceToken(deviceToken)
    }

    /// Registers the specified DeviceToken in the Zendesk Backend (if possible).
    ///
    func registerDeviceToken(_ deviceToken: String) {
        DDLogInfo("☎️ [Zendesk] Registering Device Token...")
        zendeskPushProvider?.register(deviceIdentifier: deviceToken, locale: Locale.preferredLanguage) { (_, error) in
            if let error = error {
                DDLogError("☎️ [Zendesk] Couldn't register Device Token [\(deviceToken)]. Error: \(error)")
                return
            }

            DDLogInfo("☎️ [Zendesk] Successfully registered Device Token: [\(deviceToken)]")
        }
    }

    func postNotificationReceived() {
        // Updating unread indicators should trigger UI updates, so send notification in main thread.
        DispatchQueue.main.async {
           NotificationCenter.default.post(name: .ZDPNReceived, object: nil)
        }
    }

    func postNotificationRead() {
        // Updating unread indicators should trigger UI updates, so send notification in main thread.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ZDPNCleared, object: nil)
        }
    }
}


// MARK: - ZendeskManager: SupportManagerAdapter Conformance
//
extension ZendeskManager: SupportManagerAdapter {
    /// Stores the DeviceToken. Zendesk doesn't allow us to register for APNS until an Identity has been created.
    ///
    func deviceTokenWasReceived(deviceToken: String) {
        self.deviceToken = deviceToken
    }

    /// Unregisters from the Zendesk Push Notifications Service.
    ///
    func unregisterForRemoteNotifications() {
        DDLogInfo("☎️ [Zendesk] Unregistering for Notifications...")
        zendeskPushProvider?.unregisterForPush()
    }

    /// This handles Zendesk push notifications.
    ///
    func displaySupportRequest(using userInfo: [AnyHashable: Any]) {
        guard zendeskEnabled == true,
            let requestId = userInfo[PushKey.requestID] as? String else {
                DDLogInfo("Zendesk push notification payload is invalid.")
                return
        }

        // grab the tab bar
        guard let tabBar = AppDelegate.shared.tabBarController else {
            return
        }

        // select My Store
        tabBar.navigateTo(.myStore)

        // store the navController
        guard let navController = tabBar.selectedViewController as? UINavigationController else {
            DDLogError("⛔️ Unable to navigate to Zendesk deep link. Failed to find a nav controller.")
            return
        }

        // navigate thru the stack
        let dashboard = UIStoryboard.dashboard
        let settingsID = SettingsViewController.classNameWithoutNamespaces
        let settingsVC = dashboard.instantiateViewController(withIdentifier: settingsID) as! SettingsViewController
        navController.pushViewController(settingsVC, animated: false)

        let helpID = HelpAndSupportViewController.classNameWithoutNamespaces
        let helpAndSupportVC = dashboard.instantiateViewController(withIdentifier: helpID) as! HelpAndSupportViewController
        navController.pushViewController(helpAndSupportVC, animated: false)

        // show the single ticket view instead of the ticket list
        showSingleTicketViewIfPossible(for: requestId, from: navController)
    }

    /// Delegate method for a received push notification
    ///
    func pushNotificationReceived() {
        unreadNotificationsCount += 1
        saveUnreadCount()
        postNotificationReceived()
    }
}


// MARK: - Private Extension
//
private extension ZendeskManager {

    func createIdentity(presentIn viewController: UIViewController, completion: @escaping (Bool) -> Void) {

        // If we already have an identity, do nothing.
        guard haveUserIdentity == false else {
            DDLogDebug("Using existing Zendesk identity: \(userEmail ?? ""), \(userName ?? "")")
            registerDeviceTokenIfNeeded()
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
                self.registerDeviceTokenIfNeeded()
                completion(true)
                return
            }
        }

        getUserInformationAndShowPrompt(withName: true, from: viewController) { (success, _) in
            if success {
                self.registerDeviceTokenIfNeeded()
            }

            completion(success)
        }
    }

    func getUserInformationAndShowPrompt(withName: Bool, from viewController: UIViewController, completion: @escaping onUserInformationCompletion) {
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


    // MARK: - Request Controller Configuration

    /// Important: Any time a new request controller is created, these configurations should be attached.
    /// Without it, the tickets won't appear in the correct view(s) in the web portal and they won't contain all the metadata needed to solve a ticket.
    ///
    func createRequest(supportSourceTag: String?) -> RequestUiConfiguration {

        let requestConfig = RequestUiConfiguration()

        // Set Zendesk ticket form to use
        requestConfig.ticketFormID = TicketFieldIDs.form as NSNumber

        // Set form field values
        let ticketFields = [
            CustomField(fieldId: TicketFieldIDs.appVersion, value: Bundle.main.version),
            CustomField(fieldId: TicketFieldIDs.deviceFreeSpace, value: getDeviceFreeSpace()),
            CustomField(fieldId: TicketFieldIDs.networkInformation, value: getNetworkInformation()),
            CustomField(fieldId: TicketFieldIDs.logs, value: getLogFile()),
            CustomField(fieldId: TicketFieldIDs.currentSite, value: getCurrentSiteDescription()),
            CustomField(fieldId: TicketFieldIDs.sourcePlatform, value: Constants.sourcePlatform),
            CustomField(fieldId: TicketFieldIDs.appLanguage, value: Locale.preferredLanguage),
            CustomField(fieldId: TicketFieldIDs.subcategory, value: Constants.subcategory)
        ].compactMap { $0 }

        requestConfig.customFields = ticketFields

        // Set tags
        requestConfig.tags = getTags(supportSourceTag: supportSourceTag)

        // Set the ticket subject
        requestConfig.subject = Constants.ticketSubject

        // No extra config needed to attach an image. Hooray!

        return requestConfig
    }

    // MARK: - View
    //
    func showZendeskView(_ zendeskView: UIViewController, from controller: UIViewController) {
        // Got some duck typing going on in here. Sorry.

        // If the controller is a UIViewController, set the modal display for iPad.
        if !controller.isKind(of: UINavigationController.self) && UIDevice.current.userInterfaceIdiom == .pad {
            let navController = UINavigationController(rootViewController: zendeskView)
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .crossDissolve
            controller.present(navController, animated: true)
            return
        }

        if let navController = controller as? UINavigationController {
            navController.pushViewController(zendeskView, animated: true)
            return
        }

        if let navController = controller.navigationController {
            navController.pushViewController(zendeskView, animated: true)
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

    func saveUnreadCount() {
        UserDefaults.standard.set(unreadNotificationsCount, forKey: Constants.unreadNotificationsKey)
    }

    func removeUserProfile() {
        UserDefaults.standard.removeObject(forKey: Constants.zendeskProfileUDKey)
    }

    func removeUnreadCount() {
        UserDefaults.standard.removeObject(forKey: Constants.unreadNotificationsKey)
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

        guard let logFileInformation = ServiceLocator.fileLogger.logFileManager.sortedLogFileInfos.first,
            let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
            let logText = String(data: logData, encoding: .utf8) else {
                return ""
        }

        return logText
    }

    func getCurrentSiteDescription() -> String {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return String()
        }

        return "\(site.url) (\(site.description))"
    }


    func getNetworkInformation() -> String {
        let networkType: String = {
            let reachibilityStatus = ZDKReachability.forInternetConnection().currentReachabilityStatus()
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

        let networkInformation = [
            "\(Constants.networkTypeLabel) \(networkType)",
            "\(Constants.networkCarrierLabel) \(carrierName)",
            "\(Constants.networkCountryCodeLabel) \(carrierCountryCode)"
        ]

        return networkInformation.joined(separator: "\n")
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
            textField.placeholder = LocalizedText.emailPlaceholder
            textField.text = self.userEmail

            textField.addTarget(self,
                                action: #selector(self.emailTextFieldDidChange),
                                for: UIControl.Event.editingChanged)
        }

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


// MARK: - Notifications
//
private extension ZendeskManager {

    /// Listens to Zendesk Notifications
    ///
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


    /// Handles (all of the) Zendesk Notifications
    ///
    @objc func zendeskNotification(_ notification: Notification) {
        switch notification.name.rawValue {
        case ZDKAPI_RequestSubmissionSuccess:
            ServiceLocator.analytics.track(.supportNewRequestCreated)
        case ZDKAPI_RequestSubmissionError:
            ServiceLocator.analytics.track(.supportNewRequestFailed)
        case ZDKAPI_UploadAttachmentSuccess:
            ServiceLocator.analytics.track(.supportNewRequestFileAttached)
        case ZDKAPI_UploadAttachmentError:
            ServiceLocator.analytics.track(.supportNewRequestFileAttachmentFailed)
        case ZDKAPI_CommentSubmissionSuccess:
            ServiceLocator.analytics.track(.supportTicketUserReplied)
        case ZDKAPI_CommentSubmissionError:
            ServiceLocator.analytics.track(.supportTicketUserReplyFailed)
        case ZDKAPI_RequestsError:
            ServiceLocator.analytics.track(.supportTicketListViewFailed)
        case ZDKAPI_CommentListSuccess:
            ServiceLocator.analytics.track(.supportTicketUserViewed)
        case ZDKAPI_CommentListError:
            ServiceLocator.analytics.track(.supportTicketViewFailed)
        case ZD_HC_SearchSuccess:
            ServiceLocator.analytics.track(.supportHelpCenterUserSearched)
        default:
            break
        }
    }
}


// MARK: - Nested Types
//
private extension ZendeskManager {

    // MARK: - Constants
    //
    struct Constants {
        static let unknownValue = "unknown"
        static let noValue = "none"
        static let mobileCategoryID: UInt64 = 360000041586
        static let articleLabel = "iOS"
        static let platformTag = "iOS"
        static let sdkTag = "woo-mobile-sdk"
        static let ticketSubject = NSLocalizedString(
            "WooCommerce for iOS Support",
            comment: "Subject of new Zendesk ticket."
        )
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
        static let unreadNotificationsKey = "wc_zendesk_unread_notifications"
        static let nameFieldCharacterLimit = 50
        static let sourcePlatform = "mobile_-_woo_ios"
        static let subcategory = "WooCommerce Mobile Apps"
    }

    // Zendesk expects these as NSNumber. However, they are defined as UInt64 to satisfy 32-bit devices (ex: iPhone 5).
    // Which means they then have to be converted to NSNumber when sending to Zendesk.
    struct TicketFieldIDs {
        static let form: Int64 = 360000010286
        static let appVersion: Int64 = 360000086866
        static let allBlogs: Int64 = 360000087183
        static let deviceFreeSpace: Int64 = 360000089123
        static let networkInformation: Int64 = 360000086966
        static let logs: Int64 = 22871957
        static let currentSite: Int64 = 360000103103
        static let sourcePlatform: Int64 = 360009311651
        static let appLanguage: Int64 = 360008583691
        static let subcategory: Int64 = 25176023
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

    struct PushKey {
        static let requestID = "zendesk_sdk_request_id"
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
