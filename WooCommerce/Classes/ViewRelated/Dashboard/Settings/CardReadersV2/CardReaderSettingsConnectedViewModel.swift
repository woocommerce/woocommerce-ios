import Foundation
import Yosemite

final class CardReaderSettingsConnectedViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var didGetConnectedReaders: Bool = false
    private var connectedReaders = [CardReader]()
    private let knownReadersProvider: CardReaderSettingsKnownReadersProvider?
    private(set) var readerUpdateAvailable: CardReaderSettingsTriState = .isUnknown

    var connectedReaderID: String?
    var connectedReaderBatteryLevel: String?

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?, knownReadersProvider: CardReaderSettingsKnownReadersProvider? = nil) {
        self.didChangeShouldShow = didChangeShouldShow
        self.knownReadersProvider = knownReadersProvider
        beginObservation()
    }

    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of
    /// connected readers.
    ///
    private func beginObservation() {
        // This completion should be called repeatedly as the list of connected readers changes
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.didGetConnectedReaders = true
            self.connectedReaders = readers
            self.updateProperties()
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(action)
    }

    private func updateProperties() {
        guard connectedReaders.count > 0 else {
            connectedReaderID = nil
            connectedReaderBatteryLevel = nil
            return
        }

        connectedReaderID = connectedReaders[0].id

        guard let batteryLevel = connectedReaders[0].batteryLevel else {
            connectedReaderBatteryLevel = Localization.unknownBatteryStatus
            return
        }

        let batteryLevelPercent = Int(100 * batteryLevel)
        let batteryLevelString = NumberFormatter.localizedString(from: batteryLevelPercent as NSNumber, number: .decimal)
        connectedReaderBatteryLevel = String.localizedStringWithFormat(Localization.batteryLabelFormat, batteryLevelString)
    }

    /// Dispatch a request to check for reader updates
    ///
    func checkForCardReaderUpdate() {
        let action = CardPresentPaymentAction.checkForCardReaderUpdate() { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let update):
                self.readerUpdateAvailable = update != nil ? .isTrue : .isFalse
            case .failure:
                DDLogError("Unexpected error when checking for reader update")
                self.readerUpdateAvailable = .isFalse
            }
            self.didUpdate?()
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Dispatch a request to disconnect from a reader
    ///
    func disconnectReader() {
        ServiceLocator.analytics.track(.cardReaderDisconnectTapped)

        if connectedReaderID != nil {
            knownReadersProvider?.forgetCardReader(cardReaderID: connectedReaderID!)
        }

        let action = CardPresentPaymentAction.disconnect() { result in
            guard result.isSuccess else {
                DDLogError("Unexpected error when disconnecting reader")
                return
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        var newShouldShow: CardReaderSettingsTriState = .isUnknown

        if !didGetConnectedReaders {
            newShouldShow = .isUnknown
        } else if connectedReaders.isEmpty {
            newShouldShow = .isFalse
        } else {
            newShouldShow = .isTrue
        }

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }
}

// MARK: - Localization
//
private extension CardReaderSettingsConnectedViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Connected Reader",
            comment: "Settings > Manage Card Reader > Connected Reader Table Section Heading"
        )

        static let unknownBatteryStatus = NSLocalizedString(
            "Unknown Battery Level",
            comment: "Displayed in the unlikely event a card reader has an indeterminate battery status"
        )

        static let batteryLabelFormat = NSLocalizedString(
            "%1$@%% Battery",
            comment: "Card reader battery level as an integer percentage"
        )
    }
}
