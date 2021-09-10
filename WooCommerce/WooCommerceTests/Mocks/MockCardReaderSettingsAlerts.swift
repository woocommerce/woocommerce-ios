import Foundation
import UIKit
@testable import WooCommerce

enum MockCardReaderSettingsAlertsMode {
    case cancelScanning
    case closeScanFailure
    case continueSearching
    case connectFoundReader
}

final class MockCardReaderSettingsAlerts: CardReaderSettingsAlertsProvider {
    private var mode: MockCardReaderSettingsAlertsMode

    init(mode: MockCardReaderSettingsAlertsMode) {
        self.mode = mode
    }
    func scanningForReader(from: UIViewController, cancel: @escaping () -> Void) {
        if mode == .cancelScanning {
            cancel()
        }
    }

    func scanningFailed(from: UIViewController, error: Error, close: @escaping () -> Void) {
        if mode == .closeScanFailure {
            close()
        }
    }

    func foundReader(from: UIViewController, name: String, connect: @escaping () -> Void, continueSearch: @escaping () -> Void) {
        if mode == .continueSearching {
            continueSearch()
        }

        if mode == .connectFoundReader {
            connect()
        }
    }

    func updateProgress(from: UIViewController, progress: Float, cancel: (() -> Void)?) {
        // GNDN
    }

    func connectingToReader(from: UIViewController) {
        // GNDN
    }

    func dismiss() {
        // GNDN
    }
}
