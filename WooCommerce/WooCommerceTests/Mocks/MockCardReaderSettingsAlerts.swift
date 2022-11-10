import Foundation
import UIKit
import Yosemite
@testable import WooCommerce

enum MockCardReaderSettingsAlertsMode {
    case cancelScanning
    case closeScanFailure
    case continueSearching
    case connectFoundReader
    case connectFirstFound
    case cancelFoundSeveral
    case cancelFoundReader
    case continueSearchingAfterConnectionFailure
    case cancelSearchingAfterConnectionFailure
}

final class MockCardReaderSettingsAlerts {
    private var mode: MockCardReaderSettingsAlertsMode
    private var didPresentFoundReader: Bool

    init(mode: MockCardReaderSettingsAlertsMode) {
        self.mode = mode
        self.didPresentFoundReader = false
    }

    func update(mode: MockCardReaderSettingsAlertsMode) {
        self.mode = mode
    }
}

extension MockCardReaderSettingsAlerts: CardReaderSettingsAlertsProvider {
    func scanningForReader(from: UIViewController, cancel: @escaping () -> Void) {
        if mode == .cancelScanning {
            cancel()
        }

        if mode == .continueSearchingAfterConnectionFailure {
            /// If we've already presented a found reader once before, cancel this second search
            ///
            if didPresentFoundReader {
                cancel()
            }
        }
    }

    func scanningFailed(from: UIViewController, error: Error, close: @escaping () -> Void) {
        if mode == .closeScanFailure {
            close()
        }
    }

    func foundReader(from: UIViewController,
                     name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) {
        didPresentFoundReader = true

        switch mode {
        case .continueSearching:
            continueSearch()
        case .connectFoundReader, .cancelSearchingAfterConnectionFailure, .continueSearchingAfterConnectionFailure:
            connect()
        case .cancelFoundReader:
            cancelSearch()
        default:
            break
        }
    }

    func updateProgress(from: UIViewController, requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) {
        // GNDN
    }

    func connectingToReader(from: UIViewController) {
        // GNDN
    }

    func foundSeveralReaders(from: UIViewController, readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        let readerID = readerIDs.first ?? ""

        if mode == .connectFirstFound {
            connect(readerID)
        }

        if mode == .cancelFoundSeveral {
            cancelSearch()
        }
    }

    func connectingFailed(from: UIViewController, continueSearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) {
        if mode == .continueSearchingAfterConnectionFailure {
            continueSearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
    }

    func connectingFailedIncompleteAddress(from: UIViewController,
                                           openWCSettings: ((UIViewController) -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
    }

    func connectingFailedInvalidPostalCode(from: UIViewController,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
    }

    func connectingFailedCriticallyLowBattery(from: UIViewController,
                                              retrySearch: @escaping () -> Void,
                                              cancelSearch: @escaping () -> Void) {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
    }

    func updatingFailedLowBattery(from: UIViewController, batteryLevel: Double?, close: @escaping () -> Void) {
        close()
    }

    func updatingFailed(from: UIViewController, tryAgain: (() -> Void)?, close: @escaping () -> Void) {
        close()
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        // GNDN
    }

    func dismiss() {
        // GNDN
    }

    func preparingLocalReader(from: UIViewController, cancel: @escaping () -> Void) {
        if mode == .cancelScanning {
            cancel()
        }
    }

    func selectSearchType(from: UIViewController, options: [Yosemite.CardReaderDiscoveryMethod : (() -> Void)]) {
        guard let bluetoothScanTapped = options[.bluetoothProximity] else {
            return
        }
        bluetoothScanTapped()
    }

    func connectingToLocalReader(from: UIViewController) {
        // GNDN
    }

}
