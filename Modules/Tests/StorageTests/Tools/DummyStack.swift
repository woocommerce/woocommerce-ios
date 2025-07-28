import Foundation
import CoreData
@testable import Storage



/// Dummy Sample Entity
///
class DummyEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var value: Int
}


/// InMemory Stack with Dynamic Model
///
class DummyStack {
    lazy var model: NSManagedObjectModel = {
        // Attributes
        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .stringAttributeType

        let valueAttribute = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .integer64AttributeType

        // Entity
        let entity = NSEntityDescription()
        entity.name = DummyEntity.entityName
        entity.managedObjectClassName = String(reflecting: DummyEntity.self)
        entity.properties = [keyAttribute, valueAttribute]

        // Tadaaaa
        let model = NSManagedObjectModel()
        model.entities = [entity]

        return model
    }()

    lazy var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.coordinator
        return context
    }()

    lazy var coordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        _ = try? coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

        return coordinator
    }()
}
