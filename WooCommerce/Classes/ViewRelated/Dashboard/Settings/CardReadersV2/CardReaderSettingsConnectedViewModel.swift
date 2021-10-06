import Foundation
import Yosemite

final class CardReaderSettingsConnectedViewModel: CardReaderSettingsPresentedViewModel {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var didGetConnectedReaders: Bool = false
    private var connectedReaders = [CardReader]()
    private let knownReaderProvider: CardReaderSettingsKnownReaderProvider?

    private(set) var checkForReaderUpdateInProgress: Bool = false
    private(set) var readerUpdateAvailable: CardReaderSettingsTriState = .isUnknown
    private(set) var readerBatteryTooLowForUpdates: Bool = false
    private(set) var readerUpdateInProgress: Bool = false
    private(set) var readerUpdateCompletedSuccessfully: Bool = false

    private(set) var readerDisconnectInProgress: Bool = false

    var connectedReaderID: String?
    var connectedReaderBatteryLevel: String?
    var connectedReaderSoftwareVersion: String?

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?, knownReaderProvider: CardReaderSettingsKnownReaderProvider? = nil) {
        self.didChangeShouldShow = didChangeShouldShow
        self.knownReaderProvider = knownReaderProvider
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
        updateReaderID()
        updateBatteryLevel()
        updateSoftwareVersion()
        didUpdate?()
    }

    private func updateReaderID() {
        connectedReaderID = connectedReaders.first?.id
    }

    private func updateBatteryLevel() {
        guard let batteryLevel = connectedReaders.first?.batteryLevel else {
            connectedReaderBatteryLevel = Localization.unknownBatteryStatus
            return
        }

        readerBatteryTooLowForUpdates = batteryLevel < Constants.batteryLevelNeededForUpdates

        let batteryLevelPercent = Int(100 * batteryLevel)
        let batteryLevelString = NumberFormatter.localizedString(from: batteryLevelPercent as NSNumber, number: .decimal)
        connectedReaderBatteryLevel = String.localizedStringWithFormat(Localization.batteryLabelFormat, batteryLevelString)
    }

    private func updateSoftwareVersion() {
        guard let softwareVersion = connectedReaders.first?.softwareVersion else {
            connectedReaderSoftwareVersion = Localization.unknownSoftwareVersion
            return
        }

        connectedReaderSoftwareVersion = String.localizedStringWithFormat(Localization.versionLabelFormat, softwareVersion)
    }

    /// Dispatch a request to check for reader updates
    ///
    func checkForCardReaderUpdate() {
        guard !checkForReaderUpdateInProgress else {
            return
        }

        readerUpdateAvailable = .isUnknown
        checkForReaderUpdateInProgress = true
        didUpdate?()

        let action = CardPresentPaymentAction.checkForCardReaderUpdate() { [weak self] result in
            guard let self = self else {
                return
            }
            guard !self.readerDisconnectInProgress else {
                return
            }
            switch result {
            case .success(let update):
                self.readerUpdateAvailable = update != nil ? .isTrue : .isFalse
            case .failure:
                DDLogError("Unexpected error when checking for reader update")
                self.readerUpdateAvailable = .isFalse
            }
            self.checkForReaderUpdateInProgress = false
            self.didUpdate?()
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Allows the view controller to kick off a card reader update
    ///
    func startCardReaderUpdate() {
        self.readerUpdateCompletedSuccessfully = false

        let action = CardPresentPaymentAction.startCardReaderUpdate(
            onProgress: { [weak self] progress in
                guard let self = self else {
                    return
                }
                self.readerUpdateInProgress = true
                self.didUpdate?()
            },
            onCompletion: { [weak self] result in
                guard let self = self else {
                    return
                }
                if case .success() = result {
                    self.readerUpdateCompletedSuccessfully = true
                    self.readerUpdateAvailable = .isFalse

                }
                self.readerUpdateInProgress = false
                self.didUpdate?()
            }
        )
        ServiceLocator.stores.dispatch(action)
    }

    /// Dispatch a request to disconnect from a reader
    ///
    func disconnectReader() {
        ServiceLocator.analytics.track(.cardReaderDisconnectTapped)

        self.readerDisconnectInProgress = true
        self.didUpdate?()

        knownReaderProvider?.forgetCardReader()

        let action = CardPresentPaymentAction.disconnect() { result in
            self.readerDisconnectInProgress = false
            self.didUpdate?()

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

// MARK: - Constants
//
private extension CardReaderSettingsConnectedViewModel {
    enum Constants {
        static let batteryLevelNeededForUpdates = Float(0.5)
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

        static let unknownSoftwareVersion = NSLocalizedString(
            "Unknown Software Version",
            comment: "Displayed in the unlikely event a card reader has an indeterminate software version"
        )

        static let versionLabelFormat = NSLocalizedString(
            "Version: %1$@",
            comment: "Displays the connected reader software version"
        )
    }
}
