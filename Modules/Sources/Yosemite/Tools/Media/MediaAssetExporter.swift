import Foundation
import MobileCoreServices
import AVFoundation
import Photos

/// Exports a media item of `PHAsset` type to be uploadable.
///
public final class MediaAssetExporter: MediaExporter {

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

    @MainActor
    func export() async throws -> UploadableMedia {
        switch asset.mediaType {
        case .image:
            return try await exportImage(forAsset: asset)
        case .video:
            return try await exportVideo(forAsset: asset)
        default:
            throw AssetExportError.unsupportedPHAssetMediaType
        }
    }

    @MainActor
    private func exportImage(forAsset asset: PHAsset) async throws -> UploadableMedia {
        guard asset.mediaType == .image else {
            throw AssetExportError.expectedPHAssetImageType
        }
        var filename = UUID().uuidString + ".jpg"
        var resourceAvailableLocally = false
        // Get the resource matching the type, to export.
        let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .photo })
        if let resource = resources.first {
            resourceAvailableLocally = true
            filename = resource.originalFilename
            if resource.uniformTypeIdentifier == UTType.gif.identifier {
                // Handles GIF export differently from images.
                return try await exportGIF(forAsset: asset, resource: resource)
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

        // Request the image.
        let (data, uti, _, info) = await requestImage(asset: asset, options: options)
        guard let imageData = data else {
            guard let error = info?[PHImageErrorKey] as? Error else {
                throw AssetExportError.failedLoadingPHImageManagerRequest
            }
            throw error
        }

        let typeHint = preferredExportTypeFor(uti: uti)

        // Hands off the image export to a shared image writer.
        let exporter = MediaImageExporter(data: imageData,
                                          filename: filename,
                                          altText: nil,
                                          typeHint: typeHint,
                                          options: imageOptions,
                                          mediaDirectoryType: mediaDirectoryType)
        return try exporter.export()
    }

    @MainActor
    private func exportVideo(forAsset asset: PHAsset) async throws -> UploadableMedia {
        guard asset.mediaType == .video else {
            throw AssetExportError.expectedPHAssetVideoType
        }
        var filename = UUID().uuidString + ".mp4"
        // Get the resource matching the type, to export.
        let resources = PHAssetResource.assetResources(for: asset).filter({ $0.type == .video })
        if let resource = resources.first {
            filename = resource.originalFilename
        }

        let destinationURL = try mediaFileManager.createLocalMediaURL(filename: filename, fileExtension: nil)

        // Remove any existing file at that location
        do {
            try FileManager.default.removeItem(at: destinationURL)
        } catch {
            // nothing at the location, proceed.
        }

        DDLogDebug("☁️ Exporting video to \(destinationURL.absoluteString)")

        // Configure the options for requesting the image.
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true

        // Export the video.
        let (exportSession, info) = await requestVideo(asset: asset, options: options, destinationURL: destinationURL)
        guard let exportSession, exportSession.progress == 1.0 else {
            guard let error = info?[PHImageErrorKey] as? Error else {
                throw AssetExportError.failedToExportVideo
            }
            throw error
        }

        let finalMedia = UploadableMedia(localURL: destinationURL,
                                         filename: filename,
                                         mimeType: destinationURL.mimeTypeForPathExtension,
                                         altText: nil)
        return finalMedia
    }
}

private extension MediaAssetExporter {
    func requestImage(asset: PHAsset, options: PHImageRequestOptions?) async -> (Data?, String?, CGImagePropertyOrientation, [AnyHashable: Any]?) {
        await withCheckedContinuation { continuation in
            imageManager.requestImageDataAndOrientation(for: asset,
                                                        options: options) { (data, uti, orientation, info) in
                continuation.resume(returning: (data, uti, orientation, info))
            }
        }
    }

    func requestVideo(asset: PHAsset, options: PHVideoRequestOptions?, destinationURL: URL) async -> (AVAssetExportSession?, [AnyHashable: Any]?) {
        await withCheckedContinuation { continuation in
            imageManager.requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { exportSession, info in
                guard let exportSession else {
                    DDLogError("⛔️ Could not create export session for the selected video")
                    return continuation.resume(returning: (exportSession, info))
                }

                exportSession.outputURL = destinationURL
                exportSession.outputFileType = AVFileType.mp4 // default type

                DDLogDebug("🚀 Video export starts")
                exportSession.exportAsynchronously() {
                    DDLogDebug("🎉 Video exporting done!")
                    continuation.resume(returning: (exportSession, info))
                }

                DDLogDebug("⏳ Exporting video progress: \(exportSession.progress)")
            }
        }
    }

    func preferredExportTypeFor(uti: String?) -> String? {
        guard let uti = uti else {
            return nil
        }

        guard allowableFileExtensions.isEmpty == false,
              let fileExtensionForType = URL.fileExtensionForUTType(uti) else {
                return nil
        }
        guard allowableFileExtensions.contains(fileExtensionForType) else {
            return UTType.jpeg.identifier
        }
        return uti
    }

    /// Exports and writes an asset's GIF data to a local Media URL.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported asset.
    /// - parameter onError: Called if an error was encountered during export.
    ///
    func exportGIF(forAsset asset: PHAsset, resource: PHAssetResource) async throws -> UploadableMedia {
        guard resource.uniformTypeIdentifier == UTType.gif.identifier else {
            throw AssetExportError.expectedPHAssetGIFType
        }
        let url: URL
        do {
            url = try mediaFileManager.createLocalMediaURL(filename: resource.originalFilename,
                                                           fileExtension: "gif")
        } catch {
            throw error
        }
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        return try await writeData(resource: resource, toFile: url, options: options)
    }

    func writeData(resource: PHAssetResource, toFile url: URL, options: PHAssetResourceRequestOptions) async throws -> UploadableMedia {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHAssetResourceManager.default()
            manager.writeData(for: resource,
                              toFile: url,
                              options: options,
                              completionHandler: { error in
                if let error {
                    return continuation.resume(throwing: error)
                }
                let exported = UploadableMedia(localURL: url,
                                               filename: url.lastPathComponent,
                                               mimeType: url.mimeTypeForPathExtension,
                                               altText: nil)
                continuation.resume(returning: exported)
            })
        }
    }
}

public extension MediaAssetExporter {
    enum AssetExportError: Error {
        case unsupportedPHAssetMediaType
        case expectedPHAssetImageType
        case expectedPHAssetGIFType
        case expectedPHAssetVideoType
        case failedLoadingPHImageManagerRequest
        case unavailablePHAssetImageResource
        case failedToExportVideo

        var description: String {
            switch self {
            case .unsupportedPHAssetMediaType:
                return NSLocalizedString("The item could not be added to the Media Library.",
                                         comment: "Message shown when an asset failed to load while trying to add it to the Media library.")
            case .expectedPHAssetImageType,
                 .failedLoadingPHImageManagerRequest,
                 .unavailablePHAssetImageResource:
                return NSLocalizedString("The image could not be added to the Media Library.",
                                         comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            case .expectedPHAssetVideoType:
                return NSLocalizedString(
                    "assetExportError.expectedPHAssetVideoType.message",
                    value: "The video could not be added to the Media Library.",
                    comment: "Message shown when a video failed to load while trying to add it to the Media library."
                )
            case .expectedPHAssetGIFType:
                return NSLocalizedString("The GIF could not be added to the Media Library.",
                                         comment: "Message shown when a GIF failed to load while trying to add it to the Media library.")
            case .failedToExportVideo:
                return NSLocalizedString(
                    "assetExportError.failedToExportVideo.message",
                    value: "Failed to export the selected media.",
                    comment: "Message shown when a video file failed to export from the local library."
                )
            }
        }
    }
}
