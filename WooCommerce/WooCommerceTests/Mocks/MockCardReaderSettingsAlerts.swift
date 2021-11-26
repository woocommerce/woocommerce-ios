import Foundation
import UIKit
@testable import WooCommerce

enum MockCardReaderSettingsAlertsMode {
    case cancelScanning
    case closeScanFailure
    case continueSearching
    case connectFoundReader
    case connectFirstFound
    case cancelFoundSeveral
    case continueSearchingAfterConnectionFailure
    case cancelSearchingAfterConnectionFailure
}

final class MockCardReaderSettingsAlerts: CardReaderSettingsAlertsProvider {
    private var mode: MockCardReaderSettingsAlertsMode
    private var didPresentFoundReader: Bool

    init(mode: MockCardReaderSettingsAlertsMode) {
        self.mode = mode
        self.didPresentFoundReader = false
    }
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

    func foundReader(from: UIViewController, name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void) {
        didPresentFoundReader = true

        if mode == .continueSearching {
            continueSearch()
        }

        if mode == .connectFoundReader || mode == .cancelSearchingAfterConnectionFailure || mode == .continueSearchingAfterConnectionFailure {
            connect()
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

    func connectingFailedMissingAddress(from: UIViewController,
                                        continueSearch: @escaping () -> Void,
                                        cancelSearch: @escaping () -> Void) {
        if mode == .continueSearchingAfterConnectionFailure {
            continueSearch()
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
}
