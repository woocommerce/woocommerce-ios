import Foundation
import Storage



/// CoreDataManager WooCommerce Extensions
///
extension CoreDataManager {

    /// Returns the default CoreDataManager Instance.
    ///
    private(set) public static var global: CoreDataManager = {
        return CoreDataManager(name: Settings.databaseName)
    }()


    /// Stack Settings
    ///
    private struct Settings {
        static let databaseName = "WooCommerce"
    }
}
