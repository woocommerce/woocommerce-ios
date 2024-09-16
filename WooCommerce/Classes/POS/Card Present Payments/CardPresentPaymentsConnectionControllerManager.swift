import Foundation
import struct Yosemite.CardPresentPaymentsConfiguration

final class CardPresentPaymentsConnectionControllerManager {
    let externalReaderConnectionController: CardReaderConnectionController<CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
                                                                            CardPresentPaymentsAlertPresenterAdaptor>
    let tapToPayConnectionController: BuiltInCardReaderConnectionController<CardPresentPaymentBuiltInReaderConnectionAlertsProvider,
                                                                            CardPresentPaymentsAlertPresenterAdaptor>
    let analyticsTracker: CardReaderConnectionAnalyticsTracker

    let knownReaderProvider: CardReaderSettingsKnownReaderProvider

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         alertsPresenter: CardPresentPaymentsAlertPresenterAdaptor) {
        let analyticsTracker = CardReaderConnectionAnalyticsTracker(
            configuration: configuration,
            siteID: siteID,
            connectionType: .userInitiated)
        self.analyticsTracker = analyticsTracker
        let knownReaderProvider = CardReaderSettingsKnownReaderStorage()
        self.knownReaderProvider = knownReaderProvider
        self.externalReaderConnectionController = CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: knownReaderProvider,
            alertsPresenter: alertsPresenter,
            alertsProvider: CardPresentPaymentBluetoothReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: analyticsTracker)
        self.tapToPayConnectionController = BuiltInCardReaderConnectionController(
            forSiteID: siteID,
            alertsPresenter: alertsPresenter,
            alertsProvider: CardPresentPaymentBuiltInReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: analyticsTracker)
    }
}
