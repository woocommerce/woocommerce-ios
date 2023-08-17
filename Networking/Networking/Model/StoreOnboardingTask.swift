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
        case storeName
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
            case "store_name":
                self = .storeName
            default:
                self = .unsupported(id)
            }
        }
    }
}

private extension StoreOnboardingTask.TaskType {
    var sortOrder: Int {
        switch self {
        case .storeName:
            return 0
        case .storeDetails:
            return 1
        case .addFirstProduct:
            return 2
        case .launchStore:
            return 3
        case .customizeDomains:
            return 4
        case .payments, .woocommercePayments:
            return 5
        case .unsupported:
            return 6
        }
    }
}

extension StoreOnboardingTask: Comparable {
    public static func < (lhs: StoreOnboardingTask, rhs: StoreOnboardingTask) -> Bool {
        lhs.type.sortOrder < rhs.type.sortOrder
    }
}
