import Foundation
import struct Networking.Booking
import class WooFoundationCore.CurrencyFormatter
import class WooFoundationCore.CurrencySettings
import enum WooFoundationCore.CurrencyCode

extension BookingDetailsViewModel {
    static func formatPrice(for booking: Booking, priceString: String) -> String {
        guard let decimalPrice = Decimal(string: priceString) else {
            return priceString
        }
        return CurrencyFormatter(
            currencySettings: Self.currencySettings(for: booking)
        ).formatAmount(decimalPrice) ?? priceString
    }

    private static func currencySettings(for booking: Booking) -> CurrencySettings {
        let siteCurrencySettings = ServiceLocator.currencySettings
        guard let currencyCode = CurrencyCode(rawValue: booking.currency) else {
            return siteCurrencySettings
        }

        return CurrencySettings(
            currencyCode: currencyCode,
            currencyPosition: siteCurrencySettings.currencyPosition,
            thousandSeparator: siteCurrencySettings.groupingSeparator,
            decimalSeparator: siteCurrencySettings.decimalSeparator,
            numberOfDecimals: siteCurrencySettings.fractionDigits
        )
    }
}
