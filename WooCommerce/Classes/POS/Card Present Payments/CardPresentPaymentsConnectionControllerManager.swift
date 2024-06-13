import Foundation
import struct Yosemite.CardPresentPaymentsConfiguration

final class CardPresentPaymentsConnectionControllerManager {
    let externalReaderConnectionController: CardReaderConnectionController
    let tapToPayConnectionController: BuiltInCardReaderConnectionController
    let analyticsTracker: CardReaderConnectionAnalyticsTracker

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         alertsPresenter: any CardPresentPaymentAlertsPresenting<CardPresentPaymentsModalViewModel>) {
        let analyticsTracker = CardReaderConnectionAnalyticsTracker(
            configuration: configuration,
            siteID: siteID,
            connectionType: .userInitiated)
        self.analyticsTracker = analyticsTracker
        self.externalReaderConnectionController = CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
            alertsPresenter: alertsPresenter,
            alertsProvider: BluetoothReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: analyticsTracker)
        self.tapToPayConnectionController = BuiltInCardReaderConnectionController(
            forSiteID: siteID,
            alertsPresenter: alertsPresenter,
            alertsProvider: BuiltInReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: analyticsTracker)
    }
}
