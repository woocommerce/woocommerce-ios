import Foundation
import Storage
import CoreData

protocol MockActionHandler {
    associatedtype ActionType

    var storageManager: StorageManagerType { get }
    var objectGraph: MockObjectGraph { get }
    func handle(action: ActionType)
}

extension MockActionHandler {

    /// A helper method to keep ActionHandler switch statements clean
    func unimplementedAction<T>(action: T) where T: Action {
        fatalError("Unable to handle action: \(action.identifier) \(String(describing: action))")
    }

    /// A helper that immediately returns a success for `Result<Void>` closure patterns
    func success(_ onCompletion: (Result<(), Error>) -> Void) {
        onCompletion(.success(()))
    }

    /// A helper that immediately returns a success for `Error?` closure patterns
    func success(_ onCompletion: (Error?) -> ()) {
        onCompletion(nil)
    }

    /// A helper that immediately returns an empty array for any callback that takes an array
    func success<T>(_ onCompletion: ([T], (Error?)) -> ()) {
        onCompletion([], nil)
    }

    /// A no-op helper for write operations in MockActionHandler subclasses
    func success() {}

    /// A helper for saving mock objects into Core Data
    func save<T, U>(mocks: [T], as dataType: U.Type, onCompletion: @escaping (Error?) -> ()) where U: ReadOnlyConvertible & NSManagedObject {

        var error: Error?

        let storage = storageManager.newDerivedStorage()

        storage.perform {
            let objects: [NSManagedObject] = mocks.map {
                let newObject = storage.insertNewObject(ofType: U.self)
                newObject.update(with: $0 as! U.ReadOnlyType)
                return newObject
            }

            do {
                try storage.obtainPermanentIDs(for: objects)
            }
            catch let err {
                error = err
            }
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            onCompletion(error)
        }
    }
}
