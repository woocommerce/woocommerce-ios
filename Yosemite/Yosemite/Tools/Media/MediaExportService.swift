import Foundation
import CocoaLumberjack
import Photos

/// Exports media to the local file system for remote upload.
///
protocol MediaExportService {
    /// Exports a media asset to the local file system so that it is uploadable, asynchronously.
    ///
    /// - Parameters:
    ///   - exportable: the exportable resource where data will be read from.
    ///   - filename: optional filename.
    ///   - altText: optional alt text.
    /// - Returns: Media that is ready to be uploaded remotely.
    func export(_ exportable: ExportableAsset, filename: String?, altText: String?) async throws -> UploadableMedia
}

/// Encapsulates exporting assets such as PHAssets, images, videos, or files at URLs to `UploadableMedia`.
///
final class DefaultMediaExportService: MediaExportService {
    @MainActor
    func export(_ exportable: ExportableAsset, filename: String?, altText: String?) async throws -> UploadableMedia {
        guard let exporter = createExporter(for: exportable, filename: filename, altText: altText) else {
            preconditionFailure("An exporter needs to be available for asset: \(exportable)")
        }
        do {
            return try await exporter.export()
        } catch {
            DDLogError("Error occurred exporting to Media: \(error)")
            throw error
        }
    }
}

// MARK: MediaExporter
//
private extension DefaultMediaExportService {
    func createExporter(for exportable: ExportableAsset, filename: String?, altText: String?) -> MediaExporter? {
        switch exportable {
        case let asset as PHAsset:
            let exporter = MediaAssetExporter(asset: asset,
                                              imageOptions: Defaults.imageExportOptions,
                                              allowableFileExtensions: Defaults.allowableFileExtensions)
            return exporter
        case let image as UIImage:
            let imageOptions = MediaImageExportOptions(maximumImageSize: 3000,
                                                       imageCompressionQuality: 1.0,
                                                       stripsGeoLocationIfNeeded: true)
            return MediaUIImageExporter(image: image,
                                        imageOptions: imageOptions,
                                        filename: filename,
                                        altText: altText)
        default:
            return nil
        }
    }
}

private extension DefaultMediaExportService {
    enum Defaults {
        ///
        /// - Note: This value may or may not be honored, depending on the export implementation and underlying data.
        ///
        static let imageExportOptions = MediaImageExportOptions(maximumImageSize: 3000,
                                                                imageCompressionQuality: 0.85,
                                                                stripsGeoLocationIfNeeded: true)

        static let allowableFileExtensions = Set<String>(["jpg", "jpeg", "png", "gif"])
    }
}
