import Foundation
import Yosemite
import CoreLocation

protocol CardReaderSupportDetermining {
    func connectedReader() async -> CardReader?
    func hasPreviousTapToPayUsage() async -> Bool
    func siteSupportsTapToPayReader() -> Bool
    func deviceSupportsTapToPayReader() async -> Bool
    func firstTapToPayTransactionDate() async -> Date?
    var locationIsAuthorized: Bool { get }
}

final class CardReaderSupportDeterminer: CardReaderSupportDetermining {
    private let stores: StoresManager
    private let configuration: CardPresentPaymentsConfiguration
    private let siteID: Int64
    private var locationManager: CLLocationManager = CLLocationManager()
    private static var deviceSupportsTapToPayReader: [Int64: ExpiringBool] = [:]

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.configuration = configuration
        self.stores = stores
    }

    var locationIsAuthorized: Bool {
        switch locationManager.authorizationStatus {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            return false
        }
    }

    @MainActor
    func connectedReader() async -> CardReader? {
        await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.publishCardReaderConnections { connectionPublisher in
                _ = connectionPublisher.sink { readers in
                    continuation.resume(returning: readers.first)
                }
            }
            self.stores.dispatch(action)
        }
    }

    @MainActor
    func hasPreviousTapToPayUsage() async -> Bool {
        await firstTapToPayTransactionDate() != nil
    }

    func siteSupportsTapToPayReader() -> Bool {
        configuration.supportedReaders.contains(.tapToPay)
    }

    @MainActor
    func deviceSupportsTapToPayReader() async -> Bool {
        /// There may be crashes due to multiple consecutive calls checkDeviceSupport
        /// Limit the calls to once every 30 seconds and cache the result
        ///
        if let cachedResult = Self.deviceSupportsTapToPayReader[siteID], !cachedResult.isExpired {
            return cachedResult.value
        }


        let deviceSupportsTapToPayReader = await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.checkDeviceSupport(
                siteID: siteID,
                cardReaderType: .tapToPay,
                discoveryMethod: .tapToPay,
                minimumOperatingSystemVersionOverride: configuration.minimumOperatingSystemVersionForTapToPay) { result in
                    continuation.resume(returning: result)
                }
            stores.dispatch(action)
        }

        Self.deviceSupportsTapToPayReader[siteID] = ExpiringBool(value: deviceSupportsTapToPayReader, expirationInSeconds: 30)
        return deviceSupportsTapToPayReader
    }

    @MainActor
    func firstTapToPayTransactionDate() async -> Date? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(
                siteID: siteID,
                cardReaderType: .tapToPay) { date in
                    continuation.resume(returning: date)
            }

            self.stores.dispatch(action)
        }
    }
}

// MARK: - Helper for caching local reader device support check

private struct ExpiringBool {
    let value: Bool
    let expirationInSeconds: Int
    private let created = Date()

    var isExpired: Bool {
        Date().timeIntervalSince(created) > Double(expirationInSeconds)
    }
}
