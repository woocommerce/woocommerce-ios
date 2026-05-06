import CoreData
import Foundation

/// Loads the WooCommerce CoreData managed object model from the Storage
/// resource bundle. The model file lives in the Storage SPM target's
/// resource bundle (`Bundle.module`), which is module-internal; this is the
/// public seam for callers that need an in-memory CoreData stack and cannot
/// reach the bundle directly. The `CoreDataManager` path stays the same.
public enum WooCommerceModelLoader {
    public static func loadCurrentModel() -> NSManagedObjectModel? {
        guard let url = Bundle.storage.url(forResource: "WooCommerce", withExtension: "momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: url)
    }
}
