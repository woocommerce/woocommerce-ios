import UIKit
import Yosemite
import Storage
import class Networking.UserAgent

protocol SettingsViewModelOutput {
    typealias Section = SettingsViewController.Section

    /// Table view sections.
    ///
    var sections: [Section] { get }

    /// Announcement for the current app version
    ///
    var announcement: Yosemite.Announcement? { get }

    /// Main Account's displayName
    ///
    var accountName: String { get }

    /// Main Site's Name
    ///
    var siteName: String? { get }

    /// Main Site's URL
    ///
    var siteUrl: String? { get }
}

protocol SettingsViewModelActionsHandler {
    /// Sets up the view model and loads the settings.
    /// Presenter (SettingsViewController in this case) is responsible for calling this from viewDidLoad method.
    ///
    func onViewDidLoad()

    /// Reloads the sites when store picker gets dismissed.
    /// Presenter (SettingsViewController in this case) is responsible for calling this method when store picker is dismissed.
    ///
    func onStorePickerDismiss()
}

protocol SettingsViewModelInput {
    var presenter: SettingsViewPresenter? { get set }
}

final class SettingsViewModel: SettingsViewModelOutput, SettingsViewModelActionsHandler, SettingsViewModelInput {

    typealias Row = SettingsViewController.Row

    weak var presenter: SettingsViewPresenter?

    /// Table Sections to be rendered
    ///
    private(set) var sections: [Section] = []

    /// Main Account's displayName
    ///
    var accountName: String {
        stores.sessionManager.defaultAccount?.displayName ?? String()
    }

    /// Announcement for the current app version
    ///
    private(set) var announcement: Yosemite.Announcement?

    /// Main Site's Name
    ///
    var siteName: String? {
        stores.sessionManager.defaultSite?.name as String?
    }

    /// Main Site's URL
    ///
    var siteUrl: String? {
        stores.sessionManager.defaultSite?.url as String?
    }

    /// Sites pulled from the results controlelr
    ///
    private var sites = [Yosemite.Site]()

    /// SitesResultsController: Loads Sites from the Storage Layer.
    ///
    private let sitesResultsController: ResultsController<StorageSite>

    /// Payment Gateway Accounts Results Controller: Loads Payment Gateway Accounts from the Storage Layer
    /// e.g. WooCommerce Payments, but eventually other in-person payment accounts too
    ///
    private let paymentGatewayAccountsResultsController: ResultsController<StoragePaymentGatewayAccount>?

    private let stores: StoresManager
    private let storageManager: StorageManagerType

    init(stores: StoresManager,
         storageManager: StorageManagerType) {
        self.stores = stores
        self.storageManager = storageManager

        /// Initialize Sites Results Controller
        ///
        sitesResultsController = ResultsController(storageManager: storageManager,
                                                   matching: NSPredicate(format: "isWooCommerceActive == YES"),
                                                   sortedBy: [NSSortDescriptor(key: "name", ascending: true)])

        /// Initialize Payment Gateway Accounts Results Controller
        ///
        if let siteID = stores.sessionManager.defaultSite?.siteID {
            paymentGatewayAccountsResultsController = ResultsController(storageManager: storageManager,
                                                                        matching: NSPredicate(format: "siteID == %lld", siteID),
                                                                        sortedBy: [])
        } else {
            paymentGatewayAccountsResultsController = nil
        }
    }

    /// Sets up the view model and loads the settings.
    /// Presenter (SettingsViewController in this case) is responsible for calling this from viewDidLoad method.
    ///
    func onViewDidLoad() {
        configureResultsControllers(onReload: { [weak self] in
            self?.reloadSettings()
        })

        fetchAllResultsControllers()
        loadPaymentGatewayAccounts()
        loadWhatsNewOnWooCommerce()
        loadSites()
        reloadSettings()
    }

    /// Reloads the sites when store picker gets dismissed.
    /// Presenter (SettingsViewController in this case) is responsible for calling this method when store picker is dismissed.
    ///
    func onStorePickerDismiss() {
        loadSites()
        reloadSettings()
    }
}

private extension SettingsViewModel {
    /// Reload the sections and refresh the view (presenter)
    ///
    func reloadSettings() {
        configureSections()
        presenter?.refreshViewContent()
    }

    func loadWhatsNewOnWooCommerce() {
        stores.dispatch(AnnouncementsAction.loadSavedAnnouncement(onCompletion: { [weak self] result in
            guard let self = self else { return }
            guard let (announcement, _) = try? result.get(), announcement.appVersionName == UserAgent.bundleShortVersion else {
                return DDLogInfo("📣 There are no announcements to show!")
            }

            self.announcement = announcement
        }))
    }

    /// Load our list of sites from the sitesResultsController
    ///
    func loadSites() {
        sites = sitesResultsController.fetchedObjects
    }

    func configureSections() {
        // Selected Store
        let selectedStoreSection: Section = {
            let storeRows: [Row] = sites.count > 1 ?
                [.selectedStore, .switchStore] : [.selectedStore]
            return Section(title: Localization.selectedStoreTitle,
                           rows: storeRows,
                           footerHeight: UITableView.automaticDimension)
        }()

        // Plugins
        let pluginsSection: Section? = {
            // Show the plugins section only if the user has an `admin` role for the default store site.
            //
            guard stores.sessionManager.defaultRoles.contains(.administrator) else {
                return nil
            }

            return Section(title: Localization.pluginsTitle,
                           rows: [.plugins],
                           footerHeight: UITableView.automaticDimension)
        }()

        // Store settings
        let storeSettingsSection = Section(title: Localization.storeSettingsTitle,
                                           rows: [.inPersonPayments],
                                           footerHeight: UITableView.automaticDimension)

        // Help & Feedback
        let helpAndFeedbackSection: Section = {
            let rows: [Row]
            if couldShowBetaFeaturesRow {
                rows = [.support, .betaFeatures, .sendFeedback]
            } else {
                rows = [.support, .sendFeedback]
            }
            return Section(title: Localization.helpAndFeedbackTitle,
                           rows: rows,
                           footerHeight: UITableView.automaticDimension)
        }()

        // App Settings
        let appSettingsSection = Section(title: Localization.appSettingsTitle,
                                         rows: [.privacy],
                                         footerHeight: UITableView.automaticDimension)

        // About the App
        let aboutTheAppSection: Section = {
            let rows: [Row]
            // Show the whats new row only there is a non-nil announcement available.
            if announcement != nil {
                rows = [.about, .whatsNew, .licenses]
            } else {
                rows = [.about, .licenses]
            }
            return Section(title: Localization.aboutTheAppTitle,
                           rows: rows,
                           footerHeight: UITableView.automaticDimension)
        }()

        // Other
        let otherSection: Section = {
            let rows: [Row]
            #if DEBUG
            rows = [.deviceSettings, .wormholy]
            #else
            rows = [.deviceSettings]
            #endif
            return Section(title: Localization.otherTitle,
                           rows: rows,
                           footerHeight: CGFloat.leastNonzeroMagnitude)
        }()

        // Logout
        let logoutSection = Section(title: nil,
                                    rows: [.logout],
                                    footerHeight: CGFloat.leastNonzeroMagnitude)

        sections = [
            selectedStoreSection,
            pluginsSection,
            storeSettingsSection,
            helpAndFeedbackSection,
            appSettingsSection,
            aboutTheAppSection,
            otherSection,
            logoutSection
        ]
        .compactMap { $0 }
    }

    /// Ask the PaymentGatewayAccountStore to loadAccounts from the network and update storage
    ///
    func loadPaymentGatewayAccounts() {
        guard let siteID = stores.sessionManager.defaultSite?.siteID else {
            return
        }

        /// No need for a completion here. We will be notified of storage changes in `onDidChangeContent`
        ///
        let action = PaymentGatewayAccountAction.loadAccounts(siteID: siteID) {_ in}
        stores.dispatch(action)
    }

    /// Set up observation of the results controllers, so that when new data arrives
    /// the view can be refreshed, and then perform the initial fetch from storage.
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureResultsController(sitesResultsController, onReload: onReload)
        configureResultsController(paymentGatewayAccountsResultsController, onReload: onReload)

        func configureResultsController<T>(_ resultsController: ResultsController<T>?,
                          onReload: @escaping () -> Void) where T: ResultsControllerMutableType {
            guard let resultsController = resultsController else { return }

            resultsController.onDidChangeContent = {
                onReload()
            }

            resultsController.onDidResetContent = { [weak self] in
                guard let self = self else { return }

                /// Refetching all the results controllers is necessary after a storage reset in `onDidResetContent` callback and before reloading UI that
                /// involves more than one results controller.
                ///
                self.fetchAllResultsControllers()
                onReload()
            }
        }
    }

    /// Perform fetch all results controllers.
    ///
    private func fetchAllResultsControllers() {
        try? sitesResultsController.performFetch()
        try? paymentGatewayAccountsResultsController?.performFetch()
    }

    /// Returns `true` for the add-ons workaround.
    var couldShowBetaFeaturesRow: Bool {
        true
    }
}

// MARK: - Localizations
//
private extension SettingsViewModel {
    enum Localization {
        static let selectedStoreTitle = NSLocalizedString(
            "Selected Store",
            comment: "My Store > Settings > Selected Store information section. " +
                "This is the heading listed above the information row that displays the store website and their username."
        ).uppercased()

        static let pluginsTitle = NSLocalizedString(
            "Plugins",
            comment: "My Store > Settings > Plugins section title"
        ).uppercased()

        static let storeSettingsTitle = NSLocalizedString(
            "Store Settings",
            comment: "My Store > Settings > Store Settings section title"
        ).uppercased()

        static let helpAndFeedbackTitle = NSLocalizedString(
            "Help & Feedback",
            comment: "My Store > Settings > Help and Feedback settings section title"
        ).uppercased()

        static let appSettingsTitle = NSLocalizedString(
            "App Settings",
            comment: "My Store > Settings > App (Application) settings section title"
        ).uppercased()

        static let aboutTheAppTitle = NSLocalizedString(
            "About the App",
            comment: "My Store > Settings > About the App (Application) section title"
        ).uppercased()

        static let otherTitle = NSLocalizedString(
            "Other",
            comment: "My Store > Settings > Other app section"
        ).uppercased()
    }
}
