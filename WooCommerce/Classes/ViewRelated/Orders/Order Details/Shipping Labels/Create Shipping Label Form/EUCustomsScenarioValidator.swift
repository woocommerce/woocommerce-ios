import Foundation
import Yosemite

class EUCustomsScenarioValidator {
    static func validate(origin: ShippingLabelAddress?, destination: ShippingLabelAddress?) -> Bool {
        origin?.country == "US" && countriesFollowingEUCustoms.contains(destination?.country ?? "")
    }

    static let countriesFollowingEUCustoms = ["AT", "AUT",
                                              "BE", "BEL",
                                              "BG", "BGR",
                                              "HR", "HRV",
                                              "CY", "CYP",
                                              "CZ", "CZE",
                                              "DK", "DNK",
                                              "EE", "EST",
                                              "FI", "FIN",
                                              "FR", "FRA",
                                              "DE", "DEU",
                                              "GR", "GRC",
                                              "HU", "HUN",
                                              "IE", "IRL",
                                              "IT", "ITA",
                                              "LV", "LVA",
                                              "LT", "LTU",
                                              "LU", "LUX",
                                              "MT", "MLT",
                                              "NL", "NLD",
                                              "NO", "NOR",
                                              "PL", "POL",
                                              "PT", "PRT",
                                              "RO", "ROU",
                                              "SK", "SVK",
                                              "SI", "SVN",
                                              "ES", "ESP",
                                              "SE", "SWE",
                                              "CH", "CHE"]
}
