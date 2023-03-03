import Foundation

public struct StoreOnboardingTask: Decodable, Equatable {
    public let isComplete: Bool
    public let type: TaskType

    private enum CodingKeys: String, CodingKey {
        case isComplete
        case type = "id"
    }
}

public extension StoreOnboardingTask {
    enum TaskType: Decodable, Equatable {
        case addFirstProduct
        case launchStore
        case customizeDomains
        case payments
        case unsupported(String)

        public init(from decoder: Decoder) throws {
            let id = try decoder.singleValueContainer().decode(String.self)

            switch id {
            case "launch_site":
                self = .launchStore
            case "products":
                self = .addFirstProduct
            case "add_domain":
                self = .customizeDomains
            case "payments":
                self = .payments
            default:
                self = .unsupported(id)
            }
        }
    }
}
