import Foundation
import Combine
import Yosemite

final class CardReaderSettingsConnectedViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var didGetConnectedReaders: Bool = false
    private var connectedReaders = [CardReader]()
    private var cancellables: Set<AnyCancellable> = []

    var connectedReaderSerialNumber: String?
    var connectedReaderBatteryLevel: String?

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?) {
        self.didChangeShouldShow = didChangeShouldShow
        beginObservation()
    }

    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of
    /// connected readers.
    ///
    private func beginObservation() {
        ServiceLocator.cardReaderService.connectedReaders
            .sink { [weak self] readers in
                guard let self = self else {
                    return
                }
                self.didGetConnectedReaders = true
                self.connectedReaders = readers
                self.updateProperties()
                self.reevaluateShouldShow()
            }
            .store(in: &cancellables)
    }

    private func updateProperties() {
        guard connectedReaders.count > 0 else {
            connectedReaderSerialNumber = nil
            connectedReaderBatteryLevel = nil
            return
        }

        connectedReaderSerialNumber = connectedReaders[0].serial

        guard let batteryLevel = connectedReaders[0].batteryLevel else {
            connectedReaderBatteryLevel = Localization.unknownBatteryStatus
            return
        }

        let batteryLevelPercent = Int(100 * batteryLevel)
        let batteryLevelString = NumberFormatter.localizedString(from: batteryLevelPercent as NSNumber, number: .decimal)
        connectedReaderBatteryLevel = String.localizedStringWithFormat(Localization.batteryLabelFormat, batteryLevelString)
    }

    /// Dispatch a request to disconnect from a reader
    ///
    func disconnectReader() {
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
