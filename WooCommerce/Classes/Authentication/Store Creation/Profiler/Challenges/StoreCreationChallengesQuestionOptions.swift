import Foundation

extension StoreCreationChallengesQuestionViewModel {
    // TODO: 10386 Align with Android and send these via tracks
    enum Challenge: String, CaseIterable {
        case settingUpTheOnlineStore = "setting-up-the-online-store"
        case findingCustomers = "finding-customers"
        case managingInventory = "managing-inventory"
        case shippingAndLogistics = "shipping-and-logistics"
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
