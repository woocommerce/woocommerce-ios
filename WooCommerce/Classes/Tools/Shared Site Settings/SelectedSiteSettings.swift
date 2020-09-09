import Foundation
import Yosemite

/// Shared Settings for the selected Site
///
final class SelectedSiteSettings: NSObject {
    /// Shared Instance
    ///
    static let shared: SelectedSiteSettings = {
        let siteSettings = SelectedSiteSettings()
        siteSettings.configureResultsController()
        return siteSettings
    }()

    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager, sortedBy: [descriptor])
    }()
}

// MARK: - ResultsController
//
extension SelectedSiteSettings {

    /// Refreshes the currency settings for the current default site
    ///
    func refresh() {
        refreshResultsPredicate()
    }

    /// Setup: ResultsController
    ///
    private func configureResultsController() {
        resultsController.onDidChangeObject = { (object, indexPath, type, newIndexPath) in
            ServiceLocator.currencySettings.updateCurrencyOptions(with: object)
        }
        refreshResultsPredicate()
    }

    private func refreshResultsPredicate() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            DDLogError("Error: no siteID found when attempting to refresh CurrencySettings results predicate.")
            return
        }

        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)
        let settingTypePredicate = NSPredicate(format: "settingGroupKey ==[c] %@", SiteSettingGroup.general.rawValue)
        resultsController.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingTypePredicate])
        try? resultsController.performFetch()
        resultsController.fetchedObjects.forEach {
            ServiceLocator.currencySettings.updateCurrencyOptions(with: $0)
        }
    }
}
