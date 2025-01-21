import Foundation
import Yosemite
import CoreLocation

protocol CardReaderSupportDetermining {
    func connectedReader() async -> CardReader?
    func hasPreviousTapToPayUsage() async -> Bool
    func siteSupportsLocalMobileReader() -> Bool
    func deviceSupportsLocalMobileReader() async -> Bool
    func firstTapToPayTransactionDate() async -> Date?
    var locationIsAuthorized: Bool { get }
}

final class CardReaderSupportDeterminer: CardReaderSupportDetermining {
    private let stores: StoresManager
    private let configuration: CardPresentPaymentsConfiguration
    private let siteID: Int64
    private var locationManager: CLLocationManager = CLLocationManager()
    private static var deviceSupportsLocalMobileReader: [Int64: Bool] = [:]

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

    func siteSupportsLocalMobileReader() -> Bool {
        configuration.supportedReaders.contains(.appleBuiltIn)
    }

    @MainActor
    func deviceSupportsLocalMobileReader() async -> Bool {
        /// There may be crashes due to multiple consecutive calls checkDeviceSupport
        /// Local mobile reader (Tap to Pay) support shouldn't change during the app lifecycle
        /// Only a change in operating system version can affect it which would require a restart of the app
        ///
        if let cachedResult = Self.deviceSupportsLocalMobileReader[siteID] {
            return cachedResult
        }


        let deviceSupportsLocalMobileReader = await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.checkDeviceSupport(
                siteID: siteID,
                cardReaderType: .appleBuiltIn,
                discoveryMethod: .localMobile,
                minimumOperatingSystemVersionOverride: configuration.minimumOperatingSystemVersionForTapToPay) { result in
                    continuation.resume(returning: result)
                }
            stores.dispatch(action)
        }

        Self.deviceSupportsLocalMobileReader[siteID] = deviceSupportsLocalMobileReader
        return deviceSupportsLocalMobileReader
    }

    @MainActor
    func firstTapToPayTransactionDate() async -> Date? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(
                siteID: siteID,
                cardReaderType: .appleBuiltIn) { date in
                    continuation.resume(returning: date)
            }

            self.stores.dispatch(action)
        }
    }
}
