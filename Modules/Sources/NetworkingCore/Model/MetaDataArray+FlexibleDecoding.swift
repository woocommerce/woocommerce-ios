import Foundation

/// Extension to support flexible decoding of MetaData arrays
/// Handles both standard array format and object format keyed by index strings
extension Array where Element == MetaData {

    /// Custom decoding from container that supports both array and dictionary formats
    public static func decodeFlexibly<K>(from container: KeyedDecodingContainer<K>,
                                         forKey key: KeyedDecodingContainer<K>.Key) -> [MetaData] {
        // Try to decode as array first (standard format)
        if let metaDataArray = try? container.decode([MetaData].self, forKey: key) {
            return metaDataArray
        }

        // Try to decode as object keyed by index strings
        if let metaDataDict = try? container.decode([String: MetaData].self, forKey: key) {
            return Array(metaDataDict.values)
        }

        // Fallback to empty array
        DDLogWarn("⚠️ Could not decode metadata as either an array or object keyed by index strings. Falling back to empty array.")
        return []
    }
}
