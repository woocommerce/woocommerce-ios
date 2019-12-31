import UIKit
import Yosemite

struct ProductTaxClassListSelectorDataSource: PaginatedListSelectorDataSource {

    typealias StorageModel = StorageTaxClass

    var selected: TaxClass?

    private let siteID: Int64

    init(product: Product, selected: TaxClass?) {
        self.siteID = Int64(product.siteID)
        self.selected = selected
    }

    func createResultsController() -> ResultsController<StorageTaxClass> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageTaxClass.name, ascending: true)

        return ResultsController<StorageTaxClass>(storageManager: storageManager,
                                                              matching: predicate,
                                                              sortedBy: [descriptor])
    }

    mutating func handleSelectedChange(selected: TaxClass) {
        self.selected = selected.slug == self.selected?.slug ? nil : selected
    }

    func configureCell(cell: BasicTableViewCell, model: TaxClass) {
        cell.selectionStyle = .default
        cell.isSelected = model.slug == selected?.slug
        
        let bodyText = model.name
        cell.textLabel?.text = bodyText
    }

    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = TaxClassAction.retrieveTaxClasses(siteID: Int(siteID)) { (taxClasses, error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing tax classes: \(error)")
            }
            onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}
