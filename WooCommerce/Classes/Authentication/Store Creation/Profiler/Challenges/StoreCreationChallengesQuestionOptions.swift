import Foundation

extension StoreCreationChallengesQuestionViewModel {
    enum Challenge: String, CaseIterable {
        case settingUpTheOnlineStore = "setting_up_online_store"
        case findingCustomers = "finding_customers"
        case managingInventory = "managing_inventory"
        case shippingAndLogistics = "shipping_and_logistics"
        case other = "other"
    }

    var challenges: [Challenge] {
        Challenge.allCases
    }
}

extension StoreCreationChallengesQuestionViewModel.Challenge {
    var name: String {
        switch self {
        case .settingUpTheOnlineStore:
            return NSLocalizedString("Setting up the online store", comment: "Challenge option in the store creation challenges question.")
        case .findingCustomers:
            return NSLocalizedString("Finding customers", comment: "Challenge option in the store creation challenges question.")
        case .managingInventory:
            return NSLocalizedString("Managing inventory", comment: "Challenge option in the store creation challenges question.")
        case .shippingAndLogistics:
            return NSLocalizedString("Shipping and logistics", comment: "Challenge option in the store creation challenges question.")
        case .other:
            return NSLocalizedString("Other", comment: "Challenge option in the store creation challenges question.")
        }
    }
}
