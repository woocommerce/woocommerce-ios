import Yosemite

struct WooShippingCustomsRequirements {
    /// Checks whether a customs form is required for the given origin country/state and destination country/state.
    ///
    static func isCustomsRequired(originCountry: String?,
                                  originState: String?,
                                  destinationCountry: String?,
                                  destinationState: String?) -> Bool {
        // Special case: Any shipment from/to military addresses must have Customs
        if normalizedCode(originCountry) == Constants.usCountryCode,
           let originState = normalizedCode(originState),
           Constants.usMilitaryStates.contains(originState) {
            return true
        }
        if normalizedCode(destinationCountry) == Constants.usCountryCode,
           let destinationState = normalizedCode(destinationState),
           Constants.usMilitaryStates.contains(destinationState) {
            return true
        }

        return effectiveCustomsCountry(country: originCountry, state: originState) !=
            effectiveCustomsCountry(country: destinationCountry, state: destinationState)
    }

    /// Checks whether the given origin and destination are in the USPS domestic mail path.
    ///
    static func isUSPSDomesticMailShipment(originCountry: String?,
                                           originState: String?,
                                           destinationCountry: String?,
                                           destinationState: String?) -> Bool {
        guard let originCountry = effectiveCustomsCountry(country: originCountry, state: originState),
              let destinationCountry = effectiveCustomsCountry(country: destinationCountry, state: destinationState) else {
            return false
        }

        return USPSDomesticMailCountries.rawCountryCodes.contains(originCountry) &&
            USPSDomesticMailCountries.rawCountryCodes.contains(destinationCountry)
    }
}

private extension WooShippingCustomsRequirements {
    static func effectiveCustomsCountry(country: String?, state: String?) -> String? {
        let country = normalizedCode(country)
        let state = normalizedCode(state)

        if country == Constants.usCountryCode,
           let state,
           Constants.usTerritoryStates.contains(state) {
            return state
        }
        return country
    }

    static func normalizedCode(_ code: String?) -> String? {
        code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    enum Constants {
        /// Country code for US - to check for international shipment
        ///
        static let usCountryCode = "US"

        /// US territories can arrive as their own country code after normalization or as US states when normalization is declined.
        static let usTerritoryStates = ["AS", "GU", "MP", "PR", "VI", "UM"]

        /// These US states are a special case because they represent military bases. They're considered "domestic",
        /// but they require a Customs form to ship from/to them.
        static let usMilitaryStates = ["AA", "AE", "AP"]
    }
}
