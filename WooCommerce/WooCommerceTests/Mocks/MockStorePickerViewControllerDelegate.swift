import Yosemite
@testable import WooCommerce

final class MockStorePickerViewControllerDelegate: StorePickerViewControllerDelegate {
    var selectedStoreIDs: [Int64] = []

    func didSelectStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure) {
        selectedStoreIDs.append(storeID)
    }

    func showRoleErrorScreen(for siteID: Int64, errorInfo: StorageEligibilityErrorInfo, onCompletion: @escaping SelectStoreClosure) {}

    func restartAuthentication() {}
}
