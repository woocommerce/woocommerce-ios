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

    /// Extract version number from model version name
    /// Examples: "Model" -> 0, "Model 10" -> 10, "Model 124" -> 124
    static func extractVersionNumber(from versionName: String) -> Int {
        // Handle the base "Model" case (version 0)
        if versionName == "Model" {
            return 0
        }

        // Extract number from "Model N" pattern
        let components = versionName.components(separatedBy: " ")
        if components.count == 2, let versionNumber = Int(components[1]) {
            return versionNumber
        }

        // Fallback: couldn't parse version, assume it's very old (version 0)
        DDLogWarn("[CoreDataMigratorUtils] Could not parse version number from '\(versionName)'. Assuming version 0.")
        return 0
    }
}
