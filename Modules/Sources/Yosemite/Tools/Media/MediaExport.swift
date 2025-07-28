import Foundation
import Networking

/// Exports media to the local file system for remote upload.
///
protocol MediaExporter {

    /// The type of MediaDirectory to use for the export destination URL.
    ///
    /// - Note: This would generally be set to .uploads or .cache, but for unit testing we use .temporary.
    ///
    var mediaDirectoryType: MediaDirectory { get }

    /// Export a media to another format.
    ///
    func export() async throws -> UploadableMedia
}

/// Extension providing generic helper implementation particular to a MediaExporter.
///
extension MediaExporter {

    /// A MediaFileManager configured with the exporter's set MediaDirectory type.
    ///
    var mediaFileManager: MediaFileManager {
        return MediaFileManager(directory: mediaDirectoryType)
    }
}
