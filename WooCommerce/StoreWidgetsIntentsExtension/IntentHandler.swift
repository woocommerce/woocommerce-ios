import Intents

class IntentHandler: INExtension, StoreWidgetsConfigIntentHandling {

    func provideStoreOptionsCollection(for intent: StoreWidgetsConfigIntent, searchTerm: String?) async throws -> INObjectCollection<IntentStore> {
        guard let sitesData = UserDefaults.group?[.sharedSitesData] as? Data,
              let sitesArray = try? JSONDecoder().decode([SharedSiteData].self, from: sitesData) else {
            return INObjectCollection(items: [])
        }

        let sites = sitesArray.map { IntentStore(identifier: String($0.siteID), display: $0.siteName) }
        return INObjectCollection(items: sites)
    }

    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
