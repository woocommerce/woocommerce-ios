import UIKit
import Yosemite

struct ProductTaxClassListSelectorDataSource: PaginatedListSelectorDataSource {

    typealias StorageModel = StorageTaxClass

    var selected: TaxClass?

    private let siteID: Int64

    init(siteID: Int64, selected: TaxClass?) {
        self.siteID = siteID
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
        self.selected = selected
    }

    func isSelected(model: TaxClass) -> Bool {
        return model.slug == selected?.slug
    }

    func configureCell(cell: WooBasicTableViewCell, model: TaxClass) {
        cell.selectionStyle = .default
        cell.applyListSelectorStyle()

        let bodyText = model.name
        cell.bodyLabel.text = bodyText
    }

    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = TaxClassAction.retrieveTaxClasses(siteID: siteID) { (taxClasses, error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing tax classes: \(error)")
            }
            onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}
