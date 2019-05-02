import Foundation
import Yosemite

final class SiteCountry {
    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = AppDelegate.shared.storageManager
        let sitePredicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let settingCountryPredicate = NSPredicate(format: "settingID ==[c] %@", Constants.countryKey)

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingCountryPredicate])

        let siteIDKeyPath = #keyPath(StorageSiteSetting.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager, sectionNameKeyPath: siteIDKeyPath, matching: compoundPredicate, sortedBy: [descriptor])
        //return ResultsController<StorageSiteSetting>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    init() {
        configureResultsController()
    }

    var siteCountry: String? {
        //print("=== all objects ", resultsController.fetchedObjects)
        return resultsController.fetchedObjects.first?.value
    }

    /// Setup: ResultsController
    ///
    private func configureResultsController() {
        resultsController.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            self?.updateCountry(with: object)
        }
        resultsController.onDidChangeContent = {[weak self] in
            print("===== did change content ===")
        }
        refreshResultsPredicate()
    }

    private func refreshResultsPredicate() {
//        let sitePredicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
//        let settingTypePredicate = NSPredicate(format: "settingGroupKey ==[c] %@", SiteSettingGroup.general.rawValue)
//        resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingTypePredicate])
        try? resultsController.performFetch()
    }

    private func updateCountry(with siteSetting: SiteSetting) {
        let value = siteSetting.value

        switch siteSetting.settingID {
        case Constants.countryKey:
            print("=== country value ", value)
            //siteCountry = value
        default:
            break
        }
    }
}


// MARK: - Constants!
//
private extension SiteCountry {

    enum Constants {
        static let countryKey = "woocommerce_default_country"
    }
}
