import CoreData
import Foundation

/// Headless-only loader for the WooCommerce CoreData model. The Storage target's
/// resource bundle is module-internal, so the smoke harness discovers the
/// compiled model from loaded bundles instead of exposing a Storage API.
enum WooCommerceModelLoader {
    static func loadCurrentModel() -> NSManagedObjectModel? {
        for bundle in candidateBundles() {
            if let url = bundle.url(forResource: "WooCommerce", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }
        return nil
    }

    private static func candidateBundles() -> [Bundle] {
        var bundles: [Bundle] = []

        if let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"],
           let bundle = Bundle(path: "\(testBundlePath)/Modules_Storage.bundle") {
            bundles.append(bundle)
        }

        let loadedBundles = Bundle.allBundles + Bundle.allFrameworks
        bundles.append(contentsOf: loadedBundles)
        bundles.append(contentsOf: loadedBundles.compactMap { bundle in
            guard let resourceURL = bundle.resourceURL else { return nil }
            return Bundle(url: resourceURL.appendingPathComponent("Modules_Storage.bundle"))
        })

        return bundles
    }
}
