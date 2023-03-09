import Foundation
import CoreTelephony
import Yosemite
import protocol Storage.StorageManagerType

/// Helper that provides general device & site zendesk metadata.
///
struct SupportFormMetadataProvider {

    /// Dependencies
    private let fileLogger: Logs
    private let stores: StoresManager
    private let sessionManager: SessionManagerProtocol
    private let storageManager: StorageManagerType
    private let connectivityObserver: ConnectivityObserver

    /// Controller for fetching site plugins from Storage
    ///
    private let pluginResultsController: ResultsController<StorageSitePlugin>

    internal init(fileLogger: Logs = ServiceLocator.fileLogger,
                  stores: StoresManager = ServiceLocator.stores,
                  sessionManager: SessionManagerProtocol = ServiceLocator.stores.sessionManager,
                  storageManager: StorageManagerType = ServiceLocator.storageManager,
                  connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) {
        self.fileLogger = fileLogger
        self.stores = stores
        self.sessionManager = sessionManager
        self.storageManager = storageManager
        self.connectivityObserver = connectivityObserver
        self.pluginResultsController = Self.createPluginResultsController(sessionManager: sessionManager, storageManager: storageManager)
    }

    /// Common system & site  tags. Used in Zendesk Forms.
    ///
    func systemTags() -> [String] {
        guard let site = sessionManager.defaultSite else {
            return [Constants.platformTag] + getIPPTags()
        }

        return [
            Constants.platformTag,
            site.isWordPressComStore ? Constants.wpComTag : nil,
            site.plan.isNotEmpty ? site.plan : nil,
            stores.isAuthenticatedWithoutWPCom ? Constants.authenticatedWithApplicationPasswordTag : nil
        ].compactMap { $0 } + getIPPTags()
    }

    /// Common system & site custom fields. Used in Zendesk Forms.
    ///
    func systemFields() -> [Int64: String] {
        [
            ZendeskFieldsIDs.appVersion: Bundle.main.version,
            ZendeskFieldsIDs.deviceFreeSpace: getDeviceFreeSpace(),
            ZendeskFieldsIDs.networkInformation: getNetworkInformation(),
            ZendeskFieldsIDs.logs: getLogFile(),
            //ZendeskFieldsIDs.legacyLogs: systemStatusReport, // TODO: Migrate SSR. We need it to be async so it needs a further refactor
            ZendeskFieldsIDs.currentSite: getCurrentSiteDescription(),
            ZendeskFieldsIDs.sourcePlatform: Constants.sourcePlatform,
            ZendeskFieldsIDs.appLanguage: Locale.preferredLanguage,
        ]
    }
}


// MARK: Helpers
//
private extension SupportFormMetadataProvider {

    /// Returns a `pluginResultsController` using the latest selected site ID for predicate.
    /// It performs the initial fetch to make it ready to use.
    ///
    private static func createPluginResultsController(sessionManager: SessionManagerProtocol,
                                                      storageManager: StorageManagerType) -> ResultsController<StorageSitePlugin> {
        var sitePredicate: NSPredicate? = nil
        if let siteID = sessionManager.defaultSite?.siteID {
            sitePredicate = NSPredicate(format: "siteID == %lld", siteID)
        } else {
            DDLogError("ZendeskManager: No siteID found when attempting to initialize Plugins Results predicate.")
        }

        let pluginStatusDescriptor = [NSSortDescriptor(keyPath: \StorageSitePlugin.status, ascending: true)]
        let resultsController = ResultsController<StorageSitePlugin>(storageManager: storageManager, matching: sitePredicate, sortedBy: pluginStatusDescriptor)

        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("SupportFormMetadataProvider: Unable to update plugin results")
        }

        return resultsController
    }

    /// List of tags that reflect Stripe and WCPay plugin statuses.
    ///
    private func getIPPTags() -> [String] {
        var ippTags = [PluginStatus]()
        if let stripe = pluginResultsController.fetchedObjects.first(where: { $0.plugin == PluginSlug.stripe }) {
            if stripe.status == .active {
                ippTags.append(.stripeInstalledAndActivated)
            } else if stripe.status == .inactive {
                ippTags.append(.stripeInstalledButNotActivated)
            }
        } else {
            ippTags.append(.stripeNotInstalled)
        }
        if let wcpay = pluginResultsController.fetchedObjects.first(where: { $0.plugin == PluginSlug.wcpay }) {
            if wcpay.status == .active {
                ippTags.append(.wcpayInstalledAndActivated)
            } else if wcpay.status == .inactive {
                ippTags.append(.wcpayInstalledButNotActivated)
            }
        }
        else {
            ippTags.append(.wcpayNotInstalled)
        }
        return ippTags.map { $0.rawValue }
    }

    /// Get the device free space: EG `56.34 GB`
    ///
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

    /// Gets the content of the main/first log file. Trimmed with a character limit.
    ///
    func getLogFile() -> String {
        guard let logFileInformation = fileLogger.logFileManager.sortedLogFileInfos.first,
              let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
              let logText = String(data: logData, encoding: .utf8) else {
            return ""
        }

        // Truncates the log text so it fits in the ticket field.
        if logText.count > Constants.logFieldCharacterLimit {
            return String(logText.suffix(Constants.logFieldCharacterLimit))
        }

        return logText
    }

    /// Gets the current site description (site url + site description).
    ///
    func getCurrentSiteDescription() -> String {
        guard let site = sessionManager.defaultSite else {
            return ""
        }

        return "\(site.url) (\(site.description))"
    }

    /// Gets the current device network information. Network type, Carrier, and Country Code
    ///
    func getNetworkInformation() -> String {
        let networkType: String = {
            switch connectivityObserver.currentStatus {
            case .reachable(let type) where type == .ethernetOrWiFi:
                return Constants.networkWiFi
            case .reachable(let type) where type == .cellular:
                return Constants.networkWWAN
            default:
                return Constants.unknownValue
            }
        }()

        let networkCarrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value
        let carrierName = networkCarrier?.carrierName ?? Constants.unknownValue
        let carrierCountryCode = networkCarrier?.isoCountryCode ?? Constants.unknownValue

        let networkInformation = [
            "\(Constants.networkTypeLabel) \(networkType)",
            "\(Constants.networkCarrierLabel) \(carrierName)",
            "\(Constants.networkCountryCodeLabel) \(carrierCountryCode)"
        ]

        return networkInformation.joined(separator: "\n")
    }
}

// MARK: Definitions
//
private extension SupportFormMetadataProvider {
    /// Zendesk Form IDs
    ///
    enum ZendeskFieldsIDs {
        static let appVersion: Int64 = 360000086866
        static let deviceFreeSpace: Int64 = 360000089123
        static let networkInformation: Int64 = 360000086966
        static let legacyLogs: Int64 = 22871957
        static let logs: Int64 = 10901699622036
        static let currentSite: Int64 = 360000103103
        static let sourcePlatform: Int64 = 360009311651
        static let appLanguage: Int64 = 360008583691
    }

    /// General Tags & Values used for Zendesk
    ///
    enum Constants {
        static let unknownValue = "unknown"
        static let platformTag = "iOS"
        static let wpComTag = "wpcom"
        static let authenticatedWithApplicationPasswordTag = "application_password_authenticated"
        static let logFieldCharacterLimit = 64000
        static let networkWiFi = "WiFi"
        static let networkWWAN = "Mobile"
        static let networkTypeLabel = "Network Type:"
        static let networkCarrierLabel = "Carrier:"
        static let networkCountryCodeLabel = "Country Code:"
        static let sourcePlatform = "mobile_-_woo_ios"
    }

    /// Payments extensions Slugs
    ///
    enum PluginSlug {
        static let stripe = "woocommerce-gateway-stripe/woocommerce-gateway-stripe"
        static let wcpay = "woocommerce-payments/woocommerce-payments"
    }

    /// iPP Zendesk tags
    ///
    enum PluginStatus: String {
        case stripeNotInstalled = "woo_mobile_stripe_not_installed"
        case stripeInstalledAndActivated = "woo_mobile_stripe_installed_and_activated"
        case stripeInstalledButNotActivated = "woo_mobile_stripe_installed_and_not_activated"
        case wcpayNotInstalled = "woo_mobile_wcpay_not_installed"
        case wcpayInstalledAndActivated = "woo_mobile_wcpay_installed_and_activated"
        case wcpayInstalledButNotActivated = "woo_mobile_wcpay_installed_and_not_activated"
    }
}
