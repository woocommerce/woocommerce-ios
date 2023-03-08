import Foundation
import CoreTelephony

/// Helper that provides general device & site zendesk metadata.
///
struct SupportFormMetadataProvider {

    private let fileLogger: Logs
    private let sessionManager: SessionManager
    private let connectivityObserver: ConnectivityObserver


    func systemFields() -> [Int64: String] {
        [
            ZendeskFieldsIDs.appVersion: Bundle.main.version,
            ZendeskFieldsIDs.deviceFreeSpace: getDeviceFreeSpace(),
            ZendeskFieldsIDs.networkInformation: getNetworkInformation(),
            ZendeskFieldsIDs.logs: getLogFile(),
            //ZendeskFieldsIDs.legacyLogs: systemStatusReport, // TODO: Migrate SSR
            ZendeskFieldsIDs.currentSite: getCurrentSiteDescription(),
            ZendeskFieldsIDs.sourcePlatform: Constants.sourcePlatform,
            ZendeskFieldsIDs.appLanguage: Locale.preferredLanguage,
        ]
    }
}


// MARK: Helpers
//
private extension SupportFormMetadataProvider {
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

    enum ZendeskFieldsIDs {
//        static let form: Int64 = 360000010286
//        static let paymentsForm: Int64 = 189946
//        static let paymentsGroup: Int64 = 27709263
        static let appVersion: Int64 = 360000086866
//        static let allBlogs: Int64 = 360000087183
        static let deviceFreeSpace: Int64 = 360000089123
        static let networkInformation: Int64 = 360000086966
        static let legacyLogs: Int64 = 22871957
        static let logs: Int64 = 10901699622036
        static let currentSite: Int64 = 360000103103
        static let sourcePlatform: Int64 = 360009311651
        static let appLanguage: Int64 = 360008583691
//        static let category: Int64 = 25176003
//        static let subcategory: Int64 = 25176023
//        static let product: Int64 = 25254766
//        static let productArea: Int64 = 360025069951
    }

    enum Constants {
        static let unknownValue = "unknown"
//        static let noValue = "none"
//        static let mobileCategoryID: UInt64 = 360000041586
//        static let articleLabel = "iOS"
//        static let platformTag = "iOS"
//        static let sdkTag = "woo-mobile-sdk"
//        static let ticketSubject = NSLocalizedString(
//            "WooCommerce for iOS Support",
//            comment: "Subject of new Zendesk ticket."
//        )
//        static let blogSeperator = "\n----------\n"
//        static let jetpackTag = "jetpack"
//        static let wpComTag = "wpcom"
//        static let authenticatedWithApplicationPasswordTag = "application_password_authenticated"
        static let logFieldCharacterLimit = 64000
        static let networkWiFi = "WiFi"
        static let networkWWAN = "Mobile"
        static let networkTypeLabel = "Network Type:"
        static let networkCarrierLabel = "Carrier:"
        static let networkCountryCodeLabel = "Country Code:"
//        static let zendeskProfileUDKey = "wc_zendesk_profile"
//        static let profileEmailKey = "email"
//        static let profileNameKey = "name"
//        static let unreadNotificationsKey = "wc_zendesk_unread_notifications"
//        static let nameFieldCharacterLimit = 50
        static let sourcePlatform = "mobile_-_woo_ios"
//        static let subcategory = "WooCommerce Mobile Apps"
//        static let paymentsCategory = "support"
//        static let paymentsSubcategory = "payment"
//        static let paymentsProduct = "woocommerce_payments"
//        static let paymentsProductArea = "product_area_woo_payment_gateway"
    }
}
