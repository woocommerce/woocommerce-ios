import Foundation
import Yosemite

final class CardReaderSettingsConnectedViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?

    private var didGetConnectedReaders: Bool = false
    private var connectedReaders = [CardReader]()

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

