import CoreData
import Foundation

/// Headless-only loader for the WooCommerce CoreData model. The Storage target's
/// resource bundle is module-internal, so the smoke harness discovers the
/// compiled model from loaded bundles instead of exposing a Storage API.
enum WooCommerceModelLoader {
    static func loadCurrentModel() -> NSManagedObjectModel? {
        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            if let url = bundle.url(forResource: "WooCommerce", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }
        return nil
    }
}
