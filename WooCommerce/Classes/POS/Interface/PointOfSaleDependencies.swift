import struct Yosemite.CardPresentPaymentsConfiguration

final class PointOfSaleDependencies {
    let siteID: Int64
    let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    init(siteID: Int64,
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration) {
        self.siteID = siteID
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
    }
}
