import Foundation

extension Int64 {
    /// Present the amount for byte count
    ///
    var byteCountRepresentable: String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: self)
    }
}
