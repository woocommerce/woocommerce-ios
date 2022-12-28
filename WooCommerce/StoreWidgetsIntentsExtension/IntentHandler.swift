import Intents

class IntentHandler: INExtension, StoreWidgetsConfigIntentHandling {

    /// Function provides dynamic sites list for widgets configuration UI, filtered by `searchTerm`
    ///
    func provideStoreOptionsCollection(for intent: StoreWidgetsConfigIntent, searchTerm: String?) async throws -> INObjectCollection<IntentStore> {
        var sitesArray = getAllStores()
        if let searchTerm {
            sitesArray = sitesArray.filter { $0.siteName.range(of: searchTerm, options: .caseInsensitive) != nil }
        }
        let sites = sitesArray.map { IntentStore(identifier: String($0.siteID), display: $0.siteName) }
        return INObjectCollection(items: sites)
    }

    override func handler(for intent: INIntent) -> Any {
        return self
    }
}

private extension IntentHandler {

    /// Helper to read sites list from shared (group) UserDefaults
    ///
    func getAllStores() -> [SharedSiteData] {
        guard let sitesData = UserDefaults.group?[.sharedSitesData] as? Data,
              let sitesArray = try? JSONDecoder().decode([SharedSiteData].self, from: sitesData) else {
            // Fallback to single-store implementation
            if let storeID = UserDefaults.group?[.defaultStoreID] as? Int64,
               let storeName = UserDefaults.group?[.defaultStoreName] as? String {
                return [SharedSiteData(siteID: storeID, siteName: storeName)]
            } else {
                return []
            }
        }

        return sitesArray
    }
}
