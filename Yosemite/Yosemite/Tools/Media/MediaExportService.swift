import Foundation
import CocoaLumberjack
import Photos

/// Completion handler for a created Media object.
///
typealias MediaExportCompletion = (UploadableMedia?, Error?) -> Void

/// Exports media to the local file system for remote upload.
///
protocol MediaExportService {
    /// Exports a media asset to the local file system so that it is uploadable, asynchronously.
    ///
    /// - Parameters:
    ///     - exportable: the exportable resource where data will be read from.
    ///     - onCompletion: Called when the Media export finishes.
    ///
    func export(_ exportable: ExportableAsset, onCompletion: @escaping MediaExportCompletion)
}

/// Encapsulates exporting assets such as PHAssets, images, videos, or files at URLs to `UploadableMedia`.
///
final class DefaultMediaExportService: MediaExportService {

    private lazy var exportQueue: DispatchQueue = DispatchQueue(label: "com.woocommerce.mediaExportService",
                                                                autoreleaseFrequency: .workItem)

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
private extension DefaultMediaExportService {
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
private extension DefaultMediaExportService {
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

private extension DefaultMediaExportService {
    enum Defaults {
        ///
        /// - Note: This value may or may not be honored, depending on the export implementation and underlying data.
        ///
        static let imageExportOptions = MediaImageExportOptions(maximumImageSize: 3000,
                                                                imageCompressionQuality: 0.85,
                                                                stripsGeoLocationIfNeeded: false)

        static let allowableFileExtensions = Set<String>(["jpg", "jpeg", "png", "gif"])
    }
}
