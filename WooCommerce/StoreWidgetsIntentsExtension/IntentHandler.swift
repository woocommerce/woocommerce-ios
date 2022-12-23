import Intents

class IntentHandler: INExtension, StoreWidgetsConfigIntentHandling {

    func provideStoreOptionsCollection(for intent: StoreWidgetsConfigIntent, searchTerm: String?) async throws -> INObjectCollection<IntentStore> {
        return INObjectCollection(items: [IntentStore(identifier: "123123", display: "Test Store")])
    }

    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
