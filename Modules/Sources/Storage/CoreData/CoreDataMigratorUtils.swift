import CoreData

struct CoreDataMigratorUtils {
    /// Finds the ModelVersion that corresponds to the given NSManagedObjectModel
    static func findSourceVersion(for sourceModel: NSManagedObjectModel,
                                  in modelsInventory: ManagedObjectModelsInventory) -> ManagedObjectModelsInventory.ModelVersion? {
        do {
            let allModels = try modelsInventory.models(for: modelsInventory.versions)
            for (index, model) in allModels.enumerated() {
                if model.isEqual(sourceModel) {
                    return modelsInventory.versions[index]
                }
            }
        } catch {
            DDLogError("[CoreDataMigratorUtils] Error loading models for version detection: \(error)")
        }
        return nil
    }
}
