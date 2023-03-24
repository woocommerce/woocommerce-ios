import Foundation

public struct StoreOnboardingTask: Decodable, Equatable {
    public let isComplete: Bool
    public let type: TaskType

    private enum CodingKeys: String, CodingKey {
        case isComplete
        case type = "id"
    }

    public init(isComplete: Bool, type: TaskType) {
        self.isComplete = isComplete
        self.type = type
    }
}

public extension StoreOnboardingTask {
    enum TaskType: Decodable, Equatable {
        case storeDetails
        case addFirstProduct
        case launchStore
        case customizeDomains
        case payments
        case woocommercePayments
        case unsupported(String)

        public init(from decoder: Decoder) throws {
            let id = try decoder.singleValueContainer().decode(String.self)

            switch id {
            case "store_details":
                self = .storeDetails
            case "launch_site":
                self = .launchStore
            case "products":
                self = .addFirstProduct
            case "add_domain":
                self = .customizeDomains
            case "payments":
                self = .payments
            case "woocommerce-payments":
                self = .woocommercePayments
            default:
                self = .unsupported(id)
            }
        }
    }
}

private extension StoreOnboardingTask.TaskType {
    var sortOrder: Int {
        switch self {
        case .storeDetails:
            return 0
        case .addFirstProduct:
            return 1
        case .launchStore:
            return 2
        case .customizeDomains:
            return 3
        case .payments, .woocommercePayments:
            return 4
        case .unsupported:
            return 5
        }
    }
}

extension StoreOnboardingTask: Comparable {
    public static func < (lhs: StoreOnboardingTask, rhs: StoreOnboardingTask) -> Bool {
        lhs.type.sortOrder < rhs.type.sortOrder
    }
}
