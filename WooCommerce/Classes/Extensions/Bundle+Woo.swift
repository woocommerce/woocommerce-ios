import Foundation
import UIKit


/// Bundle: Woo Methods
///
extension Bundle {

    /// Returns the Bundle Version. If the value cannot be found, this method will return an empty string.
    ///
    var version: String {
        let version = infoDictionary?[String(kCFBundleVersionKey)] as? String
        return version ?? ""
    }
}
