import Foundation
import MobileCoreServices
import AVFoundation
import Photos

/// Media export handling of PHAssets
///
final class MediaAssetExporter: MediaExporter {

    let mediaDirectoryType: MediaDirectory

    private let imageOptions: MediaImageExportOptions

    private let allowableFileExtensions: Set<String>

    private let asset: PHAsset

    /// Default shared instance of the PHImageManager
    ///
    private lazy var imageManager = PHImageManager.default()

    init(asset: PHAsset,
         imageOptions: MediaImageExportOptions,
         allowableFileExtensions: Set<String>,
         mediaDirectoryType: MediaDirectory = .uploads) {
        self.asset = asset
        self.imageOptions = imageOptions
        self.allowableFileExtensions = allowableFileExtensions
        self.mediaDirectoryType = mediaDirectoryType
    }

    func export(onCompletion: @escaping MediaExportCompletion) {
        switch asset.mediaType {
        case .image:
            return exportImage(forAsset: asset, onCompletion: onCompletion)
        default:
            onCompletion(nil, AssetExportError.unsupportedPHAssetMediaType)
        }
    }

    private func exportImage(forAsset asset: PHAsset, onCompletion: @escaping MediaExportCompletion) {
        guard asset.mediaType == .image else {
            onCompletion(nil, AssetExportError.expectedPHAssetImageType)
            return
        }
        var filename = UUID().uuidString + ".jpg"
        var resourceAvailableLocally = false
        // Get the resource matching the type, to export.
        let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .photo })
        if let resource = resources.first {
            resourceAvailableLocally = true
            filename = resource.originalFilename
            if UTTypeEqual(resource.uniformTypeIdentifier as CFString, kUTTypeGIF) {
                // Handles GIF export differently from images.
                exportGIF(forAsset: asset, resource: resource, onCompletion: onCompletion)
                return
            }
        }

        // Configure the options for requesting the image.
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        // If we have a resource object that means we have a local copy of the asset so we can request the image in sync mode.
        options.isSynchronous = resourceAvailableLocally

        // Configure an error handler for the image request.
        let onImageRequestError: (Error?) -> Void = { (error) in
            guard let error = error else {
                onCompletion(nil, AssetExportError.failedLoadingPHImageManagerRequest)
                return
            }
            onCompletion(nil, error)
        }

        // Request the image.
        imageManager.requestImageData(for: asset,
                                      options: options,
                                      resultHandler: { [weak self] (data, uti, orientation, info) in
                                        guard let self = self else {
                                            return
                                        }

                                        guard let imageData = data else {
                                            onImageRequestError(info?[PHImageErrorKey] as? Error)
                                            return
                                        }

                                        let typeHint = self.preferredExportTypeFor(uti: uti)

                                        // Hands off the image export to a shared image writer.
                                        let exporter = MediaImageExporter(data: imageData,
                                                                          filename: filename,
                                                                          typeHint: typeHint,
                                                                          options: self.imageOptions,
                                                                          mediaDirectoryType: self.mediaDirectoryType)
                                        exporter.export(onCompletion: onCompletion)
        })
    }
}

private extension MediaAssetExporter {
    func preferredExportTypeFor(uti: String?) -> String? {
        guard let uti = uti else {
            return nil
        }

        guard allowableFileExtensions.isEmpty == false,
            let extensionType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?
            else {
                return nil
        }
        guard allowableFileExtensions.contains(extensionType) else {
            return kUTTypeJPEG as String
        }
        return uti
    }

    /// Exports and writes an asset's GIF data to a local Media URL.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported asset.
    /// - parameter onError: Called if an error was encountered during export.
    ///
    private func exportGIF(forAsset asset: PHAsset, resource: PHAssetResource, onCompletion: @escaping MediaExportCompletion) {
        guard UTTypeEqual(resource.uniformTypeIdentifier as CFString, kUTTypeGIF) else {
            onCompletion(nil, AssetExportError.expectedPHAssetGIFType)
            return
        }
        let url: URL
        do {
            url = try mediaFileManager.createLocalMediaURL(filename: resource.originalFilename,
                                                           fileExtension: "gif")
        } catch {
            onCompletion(nil, error)
            return
        }
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        let manager = PHAssetResourceManager.default()
        manager.writeData(for: resource,
                          toFile: url,
                          options: options,
                          completionHandler: { (error) in
                            guard error == nil else {
                                onCompletion(nil, error)
                                return
                            }
                            let exported = UploadableMedia(localURL: url,
                                                           filename: url.lastPathComponent,
                                                           mimeType: url.mimeTypeForPathExtension)
                            onCompletion(exported, nil)
        })
    }
}

extension MediaAssetExporter {
    enum AssetExportError: Error {
        case unsupportedPHAssetMediaType
        case expectedPHAssetImageType
        case expectedPHAssetVideoType
        case expectedPHAssetGIFType
        case failedLoadingPHImageManagerRequest
        case unavailablePHAssetImageResource
        case unavailablePHAssetVideoResource
        case failedRequestingVideoExportSession

        var description: String {
            switch self {
            case .unsupportedPHAssetMediaType:
                return NSLocalizedString("The item could not be added to the Media Library.", comment: "Message shown when an asset failed to load while trying to add it to the Media library.")
            case .expectedPHAssetImageType,
                 .failedLoadingPHImageManagerRequest,
                 .unavailablePHAssetImageResource:
                return NSLocalizedString("The image could not be added to the Media Library.", comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            case .expectedPHAssetVideoType,
                 .unavailablePHAssetVideoResource,
                 .failedRequestingVideoExportSession:
                return NSLocalizedString("The video could not be added to the Media Library.", comment: "Message shown when a video failed to load while trying to add it to the Media library.")
            case .expectedPHAssetGIFType:
                return NSLocalizedString("The GIF could not be added to the Media Library.", comment: "Message shown when a GIF failed to load while trying to add it to the Media library.")
            }
        }
    }
}
