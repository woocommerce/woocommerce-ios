import Foundation


// MARK: - Data Extensions
//
extension Data {

    /// Returns the contained data represented as an hexadecimal string
    ///
    var hexString: String {
        return reduce("") { (output, byte) in
            output + String(format: "%02x", byte)
        }
    }
}
