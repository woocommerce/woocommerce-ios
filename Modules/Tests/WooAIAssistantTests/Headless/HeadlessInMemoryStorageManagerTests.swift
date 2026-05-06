import CoreData
import Foundation
import Testing
import Storage
@testable import WooAIAssistant

struct HeadlessInMemoryStorageManagerTests {

    @Test
    func test_init_then_viewStorage_is_a_valid_managed_object_context() {
        // Given
        let manager = HeadlessInMemoryStorageManager()

        // When
        let context = manager.viewStorage as? NSManagedObjectContext

        // Then
        #expect(context != nil)
        #expect(context?.persistentStoreCoordinator?.persistentStores.isEmpty == false)
    }

    @Test
    func test_performAndSave_when_inserting_an_entity_then_it_is_readable_via_viewStorage() async {
        // Given
        let manager = HeadlessInMemoryStorageManager()

        // When
        await withCheckedContinuation { continuation in
            manager.performAndSave({ storage in
                let account = storage.insertNewObject(ofType: Storage.Account.self)
                account.userID = 99
                account.username = "demo"
            }, completion: {
                continuation.resume()
            }, on: .main)
        }

        // Then
        guard let context = manager.viewStorage as? NSManagedObjectContext else {
            Issue.record("expected NSManagedObjectContext")
            return
        }
        #expect(context.countObjects(ofType: Storage.Account.self) == 1)
    }
}
