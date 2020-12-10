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

    func unimplementedAction<T>(action: T) where T: Action {
        fatalError("Unable to handle action: \(action.identifier) \(String(describing: action))")
    }

    func success(_ onCompletion: (Result<(), Error>) -> Void) {
        onCompletion(.success(()))
    }

    func success(_ onCompletion: (Error?) -> ()) {
        onCompletion(nil)
    }

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
