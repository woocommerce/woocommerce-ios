import Storage

/// Fetches the shipping settings from the storage.
///
public final class StorageShippingSettingsService: ShippingSettingsService {
    public private(set) var dimensionUnit: String?
    public private(set) var weightUnit: String?

    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    private var siteID: Int64
    private let storageManager: CoreDataManager

    public init(siteID: Int64, storageManager: CoreDataManager) {
        self.siteID = siteID
        self.storageManager = storageManager
        configureResultsController()
    }

    public func update(siteID: Int64) {
        self.siteID = siteID
        refreshResultsPredicate(siteID: siteID)
    }
}

private extension StorageShippingSettingsService {
    func configureResultsController() {
        resultsController.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            self?.updateShippingSettings(with: object)
        }
        refreshResultsPredicate(siteID: siteID)
    }

    func refreshResultsPredicate(siteID: Int64) {
        dimensionUnit = nil
        weightUnit = nil

        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)
        let settingTypePredicate = NSPredicate(format: "settingGroupKey ==[c] %@", SiteSettingGroup.product.rawValue)
        resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingTypePredicate])
        try? resultsController.performFetch()
        resultsController.fetchedObjects.forEach {
            updateShippingSettings(with: $0)
        }
    }

    func updateShippingSettings(with siteSetting: SiteSetting) {
        let value = siteSetting.value

        switch siteSetting.settingID {
        case Constants.dimensionUnitKey:
            dimensionUnit = value
        case Constants.weightUnitKey:
            weightUnit = value
        default:
            break
        }
    }
}

// MARK: - Constants!
//
private extension StorageShippingSettingsService {

    enum Constants {
        static let dimensionUnitKey = "woocommerce_dimension_unit"
        static let weightUnitKey = "woocommerce_weight_unit"
    }
}
