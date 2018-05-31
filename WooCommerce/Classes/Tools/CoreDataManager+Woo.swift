import Foundation
import Storage


/// CoreDataManager WooCommerce Extensions
///
extension CoreDataManager {

    /// Returns the default CoreDataManager Instance.
    ///
    private(set) public static var global: CoreDataManager = {
        return CoreDataManager(name: Settings.dataStackName)
    }()


    /// Stack Settings
    ///
    private struct Settings {
        static let dataStackName = "WooCommerce"
    }
}
