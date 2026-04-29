import Foundation

public extension UnitLength {
    static func fromStoreUnit(_ unit: String) -> UnitLength {
        unit.lowercased() == "in" ? .inches : .centimeters
    }
}
