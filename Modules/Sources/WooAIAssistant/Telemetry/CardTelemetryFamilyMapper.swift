import Foundation

enum CardTelemetryFamilyMapper {

    static func family(forCardFamilyID id: CardFamilyID) -> AssistantTelemetryCardFamily {
        switch id {
        case .order:
            return .order
        case .product:
            return .product
        case .productVariation:
            return .variation
        case .customer:
            return .customer
        case .analyticsStats:
            return .analyticsStats
        }
    }
}
