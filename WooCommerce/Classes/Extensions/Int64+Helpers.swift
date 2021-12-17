import Foundation

extension Int64 {
    /// Present the amount for byte count
    ///
    var byteCountRepresentable: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .memory)
    }
}
