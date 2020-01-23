import Foundation
import CocoaLumberjack
import Photos

/// Encapsulates exporting assets such as PHAssets, images, videos, or files at URLs to `MediaUploadable`.
///
/// - Note: Methods with escaping closures will call back via its corresponding thread.
///
final class MediaExportService {
    /// Completion handler for a created Media object.
    ///
    typealias MediaExportCompletion = (UploadableMedia?, Error?) -> Void

    private lazy var exportQueue: DispatchQueue = {
        return DispatchQueue(label: "org.wordpress.mediaExportService", autoreleaseFrequency: .workItem)
    }()

    // MARK: - Instance methods

    /// Exports a media asset to the local file system so that it is uploadable, asynchronously.
    ///
    /// - Parameters:
    ///     - exportable: the exportable resource where data will be read from.
    ///     - onCompletion: Called when the Media export finishes.
    ///
    func export(_ exportable: ExportableAsset, onCompletion: @escaping MediaExportCompletion) {
        exportQueue.async {
            guard let exporter = self.createExporter(for: exportable) else {
                preconditionFailure("An exporter needs to be availale for asset: \(exportable)")
            }
            exporter.export(onCompletion: { [weak self] (exported, error) in
                guard let media = exported, error == nil else {
                    self?.handleExportError(error, onCompletion: onCompletion)
                    return
                }
                onCompletion(media, error)
            })
        }
    }
}

// MARK: MediaExporter
//
private extension MediaExportService {
    func createExporter(for exportable: ExportableAsset) -> MediaExporter? {
        switch exportable {
        case let asset as PHAsset:
            let exporter = MediaAssetExporter(asset: asset,
                                              imageOptions: Defaults.imageExportOptions,
                                              allowableFileExtensions: Defaults.allowableFileExtensions)
            return exporter
        default:
            return nil
        }
    }
}

// MARK: Error handling
//
private extension MediaExportService {
    /// Handles and logs any error encountered.
    ///
    func handleExportError(_ error: Error?, onCompletion: MediaExportCompletion) {
        guard let error = error else {
            onCompletion(nil, nil)
            return
        }
        DDLogError("Error occurred exporting to Media: \(error)")
        onCompletion(nil, error)
    }
}

private extension MediaExportService {
    enum Defaults {
        ///
        /// - Note: This value may or may not be honored, depending on the export implementation and underlying data.
        ///
        static let imageExportOptions = MediaImageExporter.Options(maximumImageSize: 3000,
                                                                   imageCompressionQuality: 0.85,
                                                                   exportImageType: nil,
                                                                   stripsGeoLocationIfNeeded: false)

        static let allowableFileExtensions = Set<String>(["jpg", "jpeg", "png", "gif"])
    }
}
