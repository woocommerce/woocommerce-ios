import Yosemite

struct WooShippingCustomsRequirements {
    /// Checks whether a customs form is required for the given origin country/state and destination country/state.
    ///
    static func isCustomsRequired(originCountry: String?,
                                  originState: String?,
                                  destinationCountry: String?,
                                  destinationState: String?) -> Bool {
        // Special case: Any shipment from/to military addresses must have Customs
        if originCountry == Constants.usCountryCode,
           Constants.usMilitaryStates.contains(where: { $0 == originState }) {
            return true
        }
        if destinationCountry == Constants.usCountryCode,
           Constants.usMilitaryStates.contains(where: { $0 == destinationState }) {
            return true
        }

        return originCountry != destinationCountry
    }
}

private extension WooShippingCustomsRequirements {
    enum Constants {
        /// Country code for US - to check for international shipment
        ///
        static let usCountryCode = "US"

        /// These US states are a special case because they represent military bases. They're considered "domestic",
        /// but they require a Customs form to ship from/to them.
        static let usMilitaryStates = ["AA", "AE", "AP"]
    }
}
