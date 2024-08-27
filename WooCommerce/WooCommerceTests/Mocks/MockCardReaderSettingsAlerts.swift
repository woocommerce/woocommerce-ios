import Foundation
import UIKit
import Yosemite
@testable import WooCommerce

enum MockCardReaderSettingsAlertsMode {
    case cancelScanning
    case closeScanFailure
    case continueSearching
    case connectFoundReader
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

extension MockCardReaderSettingsAlerts: BluetoothReaderConnnectionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentsModalViewModel

    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
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

        return MockCardPresentPaymentsModalViewModel()
    }

    func scanningFailed(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if mode == .closeScanFailure {
            close()
        }
        return MockCardPresentPaymentsModalViewModel()
    }

    func foundReader(name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
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
        return MockCardPresentPaymentsModalViewModel()
    }

    func updateProgress(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) -> CardPresentPaymentsModalViewModel {
        return MockCardPresentPaymentsModalViewModel()
    }

    func connectingToReader() -> CardPresentPaymentsModalViewModel {
        return MockCardPresentPaymentsModalViewModel()
    }

    func foundSeveralReaders(readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        return MockCardPresentPaymentsModalViewModel()
    }

    func connectingFailed(error: Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
        return MockCardPresentPaymentsModalViewModel()
    }

    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
        return MockCardPresentPaymentsModalViewModel()
    }

    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
        return MockCardPresentPaymentsModalViewModel()
    }

    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void,
                                              cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if mode == .continueSearchingAfterConnectionFailure {
            retrySearch()
        }

        if mode == .cancelSearchingAfterConnectionFailure {
            cancelSearch()
        }
        return MockCardPresentPaymentsModalViewModel()
    }

    func connectingFailedNonRetryable(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        close()
        return MockCardPresentPaymentsModalViewModel()
    }

    func updatingFailedLowBattery(batteryLevel: Double?, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        close()
        return MockCardPresentPaymentsModalViewModel()
    }

    func updatingFailed(tryAgain: (() -> Void)?, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        close()
        return MockCardPresentPaymentsModalViewModel()
    }

    func updateSeveralReadersList(readerIDs: [String]) -> CardPresentPaymentsModalViewModel {
        return MockCardPresentPaymentsModalViewModel()
    }

    func dismiss() {
        // GNDN
    }

    func selectSearchType(tapToPay: @escaping () -> Void, bluetooth: @escaping () -> Void, cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        return MockCardPresentPaymentsModalViewModel()
    }
}


struct MockCardPresentPaymentsModalViewModel: CardPresentPaymentsModalViewModel {
    var textMode: PaymentsModalTextMode = .fullInfo

    var actionsMode: PaymentsModalActionsMode = .none

    var topTitle: String = "Title"

    var topSubtitle: String? = nil

    var image: UIImage = UIImage(systemName: "circle")!

    var primaryButtonTitle: String? = nil

    var secondaryButtonTitle: String? = nil

    var auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    var bottomSubtitle: String? = nil

    var accessibilityLabel: String? = nil

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //no-op
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        //no-op
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //no-op
    }
}
