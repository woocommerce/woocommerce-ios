import Foundation
import CoreData


// MARK: - ContextManager
//
class ContextManager {

    /// Shared!
    ///
    static let shared = ContextManager()


    /// Main PersistentStoreContainer.
    ///
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WooCommerce")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    /// Default Initializer
    ///
    private init() {
        // NO-OP!
    }
}


// MARK: - Public Methods
//
extension ContextManager {

    /// Saves the Main Context.
    ///
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
