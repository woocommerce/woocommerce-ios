@testable import WooCommerce
import Foundation
import Yosemite
import Experiments

final class MockProductListViewModel: ProductsListViewModelProtocol {
    private(set) var scanToUpdateInventoryShouldBeVisible: Bool = false
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService) {
        self.featureFlagService = featureFlagService
    }

    func scanToUpdateInventoryButtonShouldBeVisible(completion: @escaping (Bool) -> (Void)) {
        guard self.featureFlagService.isFeatureFlagEnabled(.scanToUpdateInventory) else {
            scanToUpdateInventoryShouldBeVisible = false
            return completion(false)
        }
        scanToUpdateInventoryShouldBeVisible = true
        completion(true)
    }
}
