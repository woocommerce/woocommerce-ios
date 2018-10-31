import Foundation
import ZendeskSDK
import ZendeskCoreSDK
import CoreTelephony
import SafariServices
import Yosemite


/// This class provides the functionality to communicate with Zendesk for Help Center and support ticket interaction,
/// as well as displaying views for the Help Center, new tickets, and ticket list.
///
@objc class ZendeskManager: NSObject {

    // MARK: - Public Properties

    static var sharedInstance: ZendeskManager = ZendeskManager()
    static var zendeskEnabled = false
    @objc static var unreadNotificationsCount = 0

    @objc static var showSupportNotificationIndicator: Bool {
        return unreadNotificationsCount > 0
    }

    struct PushNotificationIdentifiers {
        static let key = "type"
        static let type = "zendesk"
    }

    // MARK: - Private Properties

    private override init() {}
    private var sourceTag: WordPressSupportSourceTag?

    private var userName: String?
    private var userEmail: String?
    private var deviceID: String?
    private var haveUserIdentity = false
    private var alertNameField: UITextField?

    private static var zdAppID: String?
    private static var zdUrl: String?
    private static var zdClientId: String?
    private static var presentInController: UIViewController?

    private static var appVersion: String {
        return Bundle.main.shortVersionString() ?? Constants.unknownValue
    }

    private static var appLanguage: String {
        return Locale.preferredLanguages[0]
    }

    // MARK: - Public Methods

    @objc static func setup() {
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

        ZendeskManager.sharedInstance.haveUserIdentity = getUserProfile()
        toggleZendesk(enabled: true)

        observeZendeskNotifications()
    }

    // MARK: - Show Zendesk Views

    // -TODO: in the future this should show the Zendesk Help Center.
    /// Link to the online FAQ
    ///
    func showHelpCenterIfPossible(from controller: UIViewController) {

        ZendeskManager.presentInController = controller

        WooAnalytics.shared.track(.supportBrowseOurFaqTapped)

        guard let faqURL = WooConstants.faqURL else {
            return
        }

        let safariViewController = SFSafariViewController(url: faqURL)
        safariViewController.modalPresentationStyle = .pageSheet
        ZendeskManager.presentInController.present(safariViewController, animated: true, completion: nil)
    }

    /// Displays the Zendesk New Request view from the given controller, for users to submit new tickets.
    ///
    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {

        ZendeskManager.presentInController = controller

        ZendeskManager.createIdentity { success in
            guard success else {
                return
            }

            self.sourceTag = sourceTag
            WooAnalytics.shared.track(.supportNewRequestViewed)

            let newRequestConfig = self.createRequest()
            let newRequestController = RequestUi.buildRequestUi(with: [newRequestConfig])
            ZendeskManager.showZendeskView(newRequestController)
        }
    }

    /// Displays the Zendesk Request List view from the given controller, allowing user to access their tickets.
    ///
    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: WordPressSupportSourceTag? = nil) {

        ZendeskManager.presentInController = controller

        ZendeskManager.createIdentity { success in
            guard success else {
                return
            }

            self.sourceTag = sourceTag
            WooAnalytics.shared.track(.supportTicketListViewed)

            let requestListController = RequestUi.buildRequestList()
            ZendeskManager.showZendeskView(requestListController)
        }
    }

    /// Displays an alert allowing the user to change their Support email address.
    ///
    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping (Bool) -> Void) {
        ZendeskManager.presentInController = controller

        ZendeskManager.getUserInformationAndShowPrompt(withName: false) { success in
            completion(success)
        }
    }


    // MARK: - Helpers

    /// Returns the user's Support email address.
    ///
    static func userSupportEmail() -> String? {
        let _ = getUserProfile()
        return ZendeskManager.sharedInstance.userEmail
    }

}

// MARK: - Private Extension

private extension ZendeskManager {

    static func getZendeskCredentials() -> Bool {
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

    static func toggleZendesk(enabled: Bool) {
        zendeskEnabled = enabled
        DDLogInfo("Zendesk Enabled: \(enabled)")
    }

    static func createIdentity(completion: @escaping (Bool) -> Void) {

        // If we already have an identity, do nothing.
        guard ZendeskManager.sharedInstance.haveUserIdentity == false else {
            DDLogDebug("Using existing Zendesk identity: \(ZendeskManager.sharedInstance.userEmail ?? ""), \(ZendeskManager.sharedInstance.userName ?? "")")
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
            ZendeskManager.createZendeskIdentity { success in
                guard success else {
                    DDLogInfo("Creating Zendesk identity failed.")
                    completion(false)
                    return
                }
                DDLogDebug("Using User Defaults for Zendesk identity.")
                ZendeskManager.sharedInstance.haveUserIdentity = true
                completion(true)
                return
            }
        }

        ZendeskManager.getUserInformationAndShowPrompt(withName: true) { success in
            completion(success)
        }
    }

    static func getUserInformationAndShowPrompt(withName: Bool, completion: @escaping (Bool) -> Void) {
        ZendeskManager.getUserInformationIfAvailable()
        ZendeskManager.promptUserForInformation(withName: withName) { success in
            guard success else {
                DDLogInfo("No user information to create Zendesk identity with.")
                completion(false)
                return
            }

            ZendeskManager.createZendeskIdentity { success in
                guard success else {
                    DDLogInfo("Creating Zendesk identity failed.")
                    completion(false)
                    return
                }
                DDLogDebug("Using information from prompt for Zendesk identity.")
                ZendeskManager.sharedInstance.haveUserIdentity = true
                completion(true)
                return
            }
        }
    }

    static func getUserInformationIfAvailable() {
        ZendeskManager.sharedInstance.userEmail = StoresManager.shared.sessionManager.defaultAccount?.email
        ZendeskManager.sharedInstance.userName = StoresManager.shared.sessionManager.defaultAccount?.username

        if let displayName = StoresManager.shared.sessionManager.defaultAccount?.displayName,
            !displayName.isEmpty {
            ZendeskManager.sharedInstance.userName = displayName
        }
    }

    static func createZendeskIdentity(completion: @escaping (Bool) -> Void) {

        guard let userEmail = ZendeskManager.sharedInstance.userEmail else {
            DDLogInfo("No user email to create Zendesk identity with.")
            let identity = Identity.createAnonymous()
            Zendesk.instance?.setIdentity(identity)
            completion(false)
            return
        }

        let zendeskIdentity = Identity.createAnonymous(name: ZendeskManager.sharedInstance.userName, email: userEmail)
        Zendesk.instance?.setIdentity(zendeskIdentity)
        DDLogDebug("Zendesk identity created with email '\(userEmail)' and name '\(ZendeskManager.sharedInstance.userName ?? "")'.")
        completion(true)
    }

    func createRequest() -> RequestUiConfiguration {

        let requestConfig = RequestUiConfiguration()

        // Set Zendesk ticket form to use
        requestConfig.ticketFormID = TicketFieldIDs.form as NSNumber

        // Set form field values
        var ticketFields = [ZDKCustomField]()
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appVersion as NSNumber, andValue: ZendeskManager.appVersion))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.allBlogs as NSNumber, andValue: ZendeskManager.getBlogInformation()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.deviceFreeSpace as NSNumber, andValue: ZendeskManager.getDeviceFreeSpace()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.networkInformation as NSNumber, andValue: ZendeskManager.getNetworkInformation()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.logs as NSNumber, andValue: ZendeskManager.getLogFile()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.currentSite as NSNumber, andValue: ZendeskManager.getCurrentSiteDescription()))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.sourcePlatform as NSNumber, andValue: Constants.sourcePlatform))
        ticketFields.append(ZDKCustomField(fieldId: TicketFieldIDs.appLanguage as NSNumber, andValue: ZendeskManager.appLanguage))
        requestConfig.fields = ticketFields

        // Set tags
        requestConfig.tags = ZendeskManager.getTags()

        // Set the ticket subject
        requestConfig.subject = Constants.ticketSubject

        return requestConfig
    }

    // MARK: - View

    static func showZendeskView(_ zendeskView: UIViewController) {
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

    static func saveUserProfile() {
        var userProfile = [String: String]()
        userProfile[Constants.profileEmailKey] = ZendeskManager.sharedInstance.userEmail
        userProfile[Constants.profileNameKey] = ZendeskManager.sharedInstance.userName
        DDLogDebug("Zendesk - saving profile to User Defaults: \(userProfile)")
        UserDefaults.standard.set(userProfile, forKey: Constants.zendeskProfileUDKey)
        UserDefaults.standard.synchronize()
    }

    static func getUserProfile() -> Bool {
        guard let userProfile = UserDefaults.standard.dictionary(forKey: Constants.zendeskProfileUDKey) else {
            return false
        }
        DDLogDebug("Zendesk - read profile from User Defaults: \(userProfile)")
        ZendeskManager.sharedInstance.userEmail = userProfile.valueAsString(forKey: Constants.profileEmailKey)
        ZendeskManager.sharedInstance.userName = userProfile.valueAsString(forKey: Constants.profileNameKey)
        return true
    }


    // MARK: - Data Helpers

    static func getDeviceFreeSpace() -> String {

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

    static func getLogFile() -> String {

        guard let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate,
            let fileLogger = appDelegate.logger.fileLogger,
            let logFileInformation = fileLogger.logFileManager.sortedLogFileInfos.first,
            let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
            let logText = String(data: logData, encoding: .utf8) else {
                return ""
        }

        return logText
    }

    static func getCurrentSiteDescription() -> String {
        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let blog = blogService.lastUsedBlog() else {
            return Constants.noValue
        }

        let url = blog.url ?? Constants.unknownValue
        return "\(url) (\(blog.stateDescription()))"
    }

    static func getBlogInformation() -> String {

        let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        guard let allBlogs = blogService.blogsForAllAccounts() as? [Blog], allBlogs.count > 0 else {
            return Constants.noValue
        }

        return (allBlogs.map { $0.supportDescription() }).joined(separator: Constants.blogSeperator)
    }

    static func getTags() -> [String] {

        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        // If there are no sites, then the user has an empty WP account.
        guard let allBlogs = blogService.blogsForAllAccounts() as? [Blog], allBlogs.count > 0 else {
            return [Constants.wpComTag]
        }

        // Get all unique site plans
        var tags = allBlogs.compactMap { $0.planTitle }.unique

        // If any of the sites have jetpack installed, add jetpack tag.
        let jetpackBlog = allBlogs.first { $0.jetpack?.isInstalled == true }
        if let _ = jetpackBlog {
            tags.append(Constants.jetpackTag)
        }

        // If there is a WP account, add wpcom tag.
        let accountService = AccountService(managedObjectContext: context)
        if let _ = accountService.defaultWordPressComAccount() {
            tags.append(Constants.wpComTag)
        }

        // Add sourceTag
        if let sourceTagOrigin = ZendeskManager.sharedInstance.sourceTag?.origin {
            tags.append(sourceTagOrigin)
        }

        // Add platformTag
        tags.append(Constants.platformTag)

        return tags
    }

    static func getNetworkInformation() -> String {

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

    static func promptUserForInformation(withName: Bool, completion: @escaping (Bool) -> Void) {

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

            ZendeskManager.sharedInstance.userEmail = email

            if withName {
                ZendeskManager.sharedInstance.userName = alertController?.textFields?.last?.text
            }

            saveUserProfile()
            completion(true)
            return
        }

        // Enable Submit based on email validity.
        let email = ZendeskManager.sharedInstance.userEmail ?? ""
        submitAction.isEnabled = EmailFormatValidator.validate(string: email)

        // Make Submit button bold.
        alertController.preferredAction = submitAction

        // Email Text Field
        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .always
            textField.placeholder = LocalizedText.emailPlaceholder
            textField.text = ZendeskManager.sharedInstance.userEmail

            textField.addTarget(self,
                                action: #selector(emailTextFieldDidChange),
                                for: UIControl.Event.editingChanged)
        })

        // Name Text Field
        if withName {
            alertController.addTextField { textField in
                textField.clearButtonMode = .always
                textField.placeholder = LocalizedText.namePlaceholder
                textField.text = ZendeskManager.sharedInstance.userName
                textField.delegate = ZendeskManager.sharedInstance
                ZendeskManager.sharedInstance.alertNameField = textField
            }
        }

        // Show alert
        presentInController?.present(alertController, animated: true, completion: nil)
    }

    @objc static func emailTextFieldDidChange(_ textField: UITextField) {
        guard let alertController = presentInController?.presentedViewController as? UIAlertController,
            let email = alertController.textFields?.first?.text,
            let submitAction = alertController.actions.last else {
                return
        }

        submitAction.isEnabled = EmailFormatValidator.validate(string: email)
        updateNameFieldForEmail(email)
    }

    static func updateNameFieldForEmail(_ email: String) {
        guard let alertController = presentInController?.presentedViewController as? UIAlertController,
            let nameField = alertController.textFields?.last else {
                return
        }

        guard !email.isEmpty else {
            return
        }

        // If we don't already have the user's name, generate it from the email.
        if ZendeskManager.sharedInstance.userName == nil {
            nameField.text = generateDisplayName(from: email)
        }
    }

    static func generateDisplayName(from rawEmail: String) -> String {

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

    static func observeZendeskNotifications() {
        // Ticket Attachments
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_UploadAttachmentSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_UploadAttachmentError), object: nil)

        // New Ticket Creation
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestSubmissionSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestSubmissionError), object: nil)

        // Ticket Reply
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentSubmissionSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentSubmissionError), object: nil)

        // View Ticket List
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_RequestsError), object: nil)

        // View Individual Ticket
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentListSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZDKAPI_CommentListError), object: nil)

        // Help Center
        NotificationCenter.default.addObserver(self, selector: #selector(ZendeskManager.zendeskNotification(_:)),
                                               name: NSNotification.Name(rawValue: ZD_HC_SearchSuccess), object: nil)
    }

    @objc static func zendeskNotification(_ notification: Foundation.Notification) {
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

    // MARK: - Constants

    struct Constants {
        static let unknownValue = "unknown"
        static let noValue = "none"
        static let mobileCategoryID: UInt64 = 360000041586
        static let articleLabel = "iOS"
        static let platformTag = "iOS"
        static let ticketSubject = NSLocalizedString("WordPress for iOS Support", comment: "Subject of new Zendesk ticket.")
        static let blogSeperator = "\n----------\n"
        static let jetpackTag = "jetpack"
        static let wpComTag = "wpcom"
        static let networkWiFi = "WiFi"
        static let networkWWAN = "Mobile"
        static let networkTypeLabel = "Network Type:"
        static let networkCarrierLabel = "Carrier:"
        static let networkCountryCodeLabel = "Country Code:"
        static let zendeskProfileUDKey = "wp_zendesk_profile"
        static let profileEmailKey = "email"
        static let profileNameKey = "name"
        static let nameFieldCharacterLimit = 50
        static let sourcePlatform = "mobile_-_ios"
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

// MARK: - ZDKHelpCenterConversationsUIDelegate

extension ZendeskManager: ZDKHelpCenterConversationsUIDelegate {

    func navBarConversationsUIType() -> ZDKNavBarConversationsUIType {
        // When ZDKContactUsVisibility is on, use the default right nav bar label.
        return .localizedLabel
    }

    func active() -> ZDKContactUsVisibility {
        // If we don't have the user's information, disable 'Contact Us' via the Help Center and Article view.
        if !ZendeskManager.sharedInstance.haveUserIdentity {
            return .off
        }

        return .articleListAndArticle
    }

}

// MARK: - UITextFieldDelegate

extension ZendeskManager: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == ZendeskManager.sharedInstance.alertNameField,
            let text = textField.text else {
                return true
        }

        let newLength = text.count + string.count - range.length
        return newLength <= Constants.nameFieldCharacterLimit
    }

}
