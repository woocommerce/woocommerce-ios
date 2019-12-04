import UIKit
import Yosemite

struct PaginatedProductShippingClassListSelectorDataSource: PaginatedListSelectorDataSource {

    typealias StorageModel = StorageProductShippingClass

    var selected: ProductShippingClass?

    private let siteID: Int64

    init(product: Product) {
        self.siteID = Int64(product.siteID)
        self.selected = product.productShippingClass
    }

    func createResultsController() -> ResultsController<StorageProductShippingClass> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductShippingClass.name, ascending: true)

        return ResultsController<StorageProductShippingClass>(storageManager: storageManager,
                                                              matching: predicate,
                                                              sortedBy: [descriptor])
    }

    mutating func handleSelectedChange(selected: ProductShippingClass) {
        self.selected = selected == self.selected ? nil: selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductShippingClass) {
        cell.selectionStyle = .default

        let bodyText = model.name
        cell.textLabel?.text = bodyText
    }

    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductShippingClassAction
            .synchronizeProductShippingClassModels(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing product shipping classes: \(error)")
                }
                onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}
