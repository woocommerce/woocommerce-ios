import CoreData

protocol PersistentContainerFactoryProtocol {
    func makePersistentContainer(name: String,
                                 managedObjectModel: NSManagedObjectModel,
                                 storeDescriptions: [NSPersistentStoreDescription]) -> NSPersistentContainer
}

struct PersistentContainerFactory: PersistentContainerFactoryProtocol {
    func makePersistentContainer(name: String,
                                 managedObjectModel: NSManagedObjectModel,
                                 storeDescriptions: [NSPersistentStoreDescription]) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = storeDescriptions
        return container
    }
}
