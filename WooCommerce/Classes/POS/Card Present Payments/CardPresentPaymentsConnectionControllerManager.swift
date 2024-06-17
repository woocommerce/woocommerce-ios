import Foundation
import struct Yosemite.CardPresentPaymentsConfiguration

final class CardPresentPaymentsConnectionControllerManager {
    let externalReaderConnectionController: CardReaderConnectionController<CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
                                                                            CardPresentPaymentsAlertPresenterAdaptor>
    let tapToPayConnectionController: BuiltInCardReaderConnectionController<CardPresentPaymentBuiltInReaderConnectionAlertsProvider,
                                                                            CardPresentPaymentsAlertPresenterAdaptor>
    let analyticsTracker: CardReaderConnectionAnalyticsTracker

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         alertsPresenter: CardPresentPaymentsAlertPresenterAdaptor) {
        let analyticsTracker = CardReaderConnectionAnalyticsTracker(
            configuration: configuration,
            siteID: siteID,
            connectionType: .userInitiated)
        self.analyticsTracker = analyticsTracker
        self.externalReaderConnectionController = CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
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
