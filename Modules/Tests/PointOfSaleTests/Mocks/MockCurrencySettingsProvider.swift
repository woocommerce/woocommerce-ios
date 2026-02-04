// MockCurrencySettingsProvider.swift
import Foundation
@testable import PointOfSale
import class WooFoundation.CurrencySettings

final class MockPOSCurrencySettingsProvider: POSCurrencySettingsProviding {
    let currencySettings: CurrencySettings

    init(currencySettings: CurrencySettings = CurrencySettings(currencyCode: .USD,
                                                                 currencyPosition: .left,
                                                                 thousandSeparator: ",",
                                                                 decimalSeparator: ".",
                                                                 numberOfDecimals: 2)) {
        self.currencySettings = currencySettings
    }
}
