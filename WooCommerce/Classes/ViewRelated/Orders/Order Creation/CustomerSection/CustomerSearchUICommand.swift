import Foundation
import Yosemite

final class CustomerSearchUICommand: SearchUICommand {

    typealias Model = Customer
    typealias CellViewModel = TitleAndSubtitleAndStatusTableViewCell.ViewModel
    typealias ResultsControllerModel = StorageCustomer

    var searchBarPlaceholder: String = ""

    var searchBarAccessibilityIdentifier: String = ""

    var cancelButtonAccessibilityIdentifier: String = ""

    var resynchronizeModels: (() -> Void) = {}

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func createResultsController() -> ResultsController<StorageCustomer> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageCustomer.customerID, ascending: false)
        return ResultsController<StorageCustomer>(storageManager: storageManager, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        return nil
    }

    func createCellViewModel(model: Customer) -> TitleAndSubtitleAndStatusTableViewCell.ViewModel {
        return CellViewModel(
            id: "\(model.customerID)",
            title: model.firstName ?? "",
            subtitle: model.lastName ?? "",
            accessibilityLabel: "",
            status: "",
            statusBackgroundColor: .accent
        )
    }

    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {

    }

    func didSelectSearchResult(model: Customer, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {

    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        return NSPredicate(format: "ANY searchResults.keyword = %@", keyword)
    }
}
