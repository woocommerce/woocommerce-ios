import CoreData
import Storage

extension ResultsController where T: StorageProduct {
    public convenience init(storageManager: StorageManagerType,
                            sectionNameKeyPath: String? = nil,
                            matching predicate: NSPredicate? = nil,
                            sortOrder: ProductsSortOrder) {

        self.init(storageManager: storageManager,
                  sectionNameKeyPath: sectionNameKeyPath,
                  matching: predicate,
                  sortedBy: sortOrder.sortDescriptors ?? [])
    }

    public func updateSortOrder(_ sortOrder: ProductsSortOrder) {
        sortDescriptors = sortOrder.sortDescriptors
    }
}

private extension ProductsSortOrder {
    var sortDescriptors: [NSSortDescriptor]? {
        switch self {
        case .dateAscending:
            return [NSSortDescriptor(keyPath: \StorageProduct.date, ascending: true)]
        case .dateDescending:
            return [NSSortDescriptor(keyPath: \StorageProduct.date, ascending: false)]
        case .nameAscending:
            return [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCompare(_:)))]
        case .nameDescending:
            return [NSSortDescriptor(key: "name", ascending: false, selector: #selector(NSString.localizedCompare(_:)))]
        }
    }
}
