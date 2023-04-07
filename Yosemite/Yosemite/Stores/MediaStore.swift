import Foundation
import Networking
import Storage

// MARK: - MediaStore
//
public final class MediaStore: Store {
    private let remote: MediaRemoteProtocol
    private lazy var mediaExportService: MediaExportService = DefaultMediaExportService()

    public convenience override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = MediaRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: MediaRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    convenience init(mediaExportService: MediaExportService,
         dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network) {
        let remote = MediaRemote(network: network)
        self.init(mediaExportService: mediaExportService, dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(mediaExportService: MediaExportService,
         dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: MediaRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
        self.mediaExportService = mediaExportService
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: MediaAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? MediaAction else {
            assertionFailure("MediaStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveMediaLibrary(let siteID, let pageNumber, let pageSize, let onCompletion):
            retrieveMediaLibrary(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .uploadMedia(let siteID, let productID, let mediaAsset, let onCompletion):
            uploadMedia(siteID: siteID, productID: productID, mediaAsset: mediaAsset, onCompletion: onCompletion)
        case .uploadImage(let siteID, let productID, let image, let onCompletion):
            uploadImage(siteID: siteID, productID: productID, image: image, completion: onCompletion)
        case .updateProductID(let siteID,
                            let productID,
                             let mediaID,
                             let onCompletion):
            updateProductID(siteID: siteID, productID: productID, mediaID: mediaID, onCompletion: onCompletion)
        }
    }
}

private extension MediaStore {
    func retrieveMediaLibrary(siteID: Int64,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: @escaping (Result<[Media], Error>) -> Void) {
        if isLoggedInWithoutWPCOMCredentials(siteID) || isSiteJetpackJCPConnected(siteID) {
            remote.loadMediaLibraryFromWordPressSite(siteID: siteID,
                                                     pageNumber: pageNumber,
                                                     pageSize: pageSize) { result in
                onCompletion(result.map { $0.map { $0.toMedia() } })
            }
        } else {
            remote.loadMediaLibrary(for: siteID,
                                       pageNumber: pageNumber,
                                       pageSize: pageSize,
                                       context: nil,
                                       completion: onCompletion)
        }
    }

    /// Uploads an exportable media asset to the site's WP Media Library with 2 steps:
    /// 1) Exports the media asset to a uploadable type
    /// 2) Uploads the exported media file to the server
    ///
    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     onCompletion: @escaping (Result<Media, Error>) -> Void) {
        mediaExportService.export(mediaAsset,
                                  onCompletion: { [weak self] (uploadableMedia, error) in
            guard let uploadableMedia = uploadableMedia, error == nil else {
                onCompletion(.failure(error ?? MediaActionError.unknown))
                return
            }
            self?.uploadMedia(siteID: siteID,
                              productID: productID,
                              uploadableMedia: uploadableMedia,
                              onCompletion: onCompletion)
        })
    }

    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     uploadableMedia media: UploadableMedia,
                     onCompletion: @escaping (Result<Media, Error>) -> Void) {
        if isLoggedInWithoutWPCOMCredentials(siteID) || isSiteJetpackJCPConnected(siteID) {
            remote.uploadMediaToWordPressSite(siteID: siteID,
                                              productID: productID,
                                              mediaItems: [media]) { result in
                // Removes local media after the upload API request.
                do {
                    try MediaFileManager().removeLocalMedia(at: media.localURL)
                } catch {
                    onCompletion(.failure(error))
                    return
                }

                switch result {
                case .success(let uploadedMedia):
                    onCompletion(.success(uploadedMedia.toMedia()))
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        } else {
            remote.uploadMedia(for: siteID,
                                  productID: productID,
                                  context: nil,
                                  mediaItems: [media]) { result in
                // Removes local media after the upload API request.
                do {
                    try MediaFileManager().removeLocalMedia(at: media.localURL)
                } catch {
                    onCompletion(.failure(error))
                    return
                }

                switch result {
                case .success(let uploadedMediaItems):
                    guard let uploadedMedia = uploadedMediaItems.first, uploadedMediaItems.count == 1 else {
                        onCompletion(.failure(MediaActionError.unexpectedMediaCount(count: uploadedMediaItems.count)))
                        return
                    }
                    onCompletion(.success(uploadedMedia))
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        }
    }

    func uploadImage(siteID: Int64,
                     productID: Int64,
                     image: UIImage,
                     completion: @escaping (Result<Media, Error>) -> Void) {
        Task { @MainActor in
            let media = try await export(image: image)
            // TODO-jc: refactor uploadMediaToWordPressSite to be async to reuse the result for both paths
            if isLoggedInWithoutWPCOMCredentials(siteID) || isSiteJetpackJCPConnected(siteID) {
                remote.uploadMediaToWordPressSite(siteID: siteID,
                                                  productID: productID,
                                                  mediaItems: [media]) { result in
                    // Removes local media after the upload API request.
                    do {
                        try MediaFileManager().removeLocalMedia(at: media.localURL)
                    } catch {
                        completion(.failure(error))
                        return
                    }

                    switch result {
                    case .success(let uploadedMedia):
                        completion(.success(uploadedMedia.toMedia()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                remote.uploadMedia(for: siteID,
                                   productID: productID,
                                   context: nil,
                                   mediaItems: [media]) { result in
                    // Removes local media after the upload API request.
                    do {
                        try MediaFileManager().removeLocalMedia(at: media.localURL)
                    } catch {
                        completion(.failure(error))
                        return
                    }

                    switch result {
                    case .success(let uploadedMediaItems):
                        guard let uploadedMedia = uploadedMediaItems.first, uploadedMediaItems.count == 1 else {
                            completion(.failure(MediaActionError.unexpectedMediaCount(count: uploadedMediaItems.count)))
                            return
                        }
                        completion(.success(uploadedMedia))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: @escaping (Result<Media, Error>) -> Void) {
        if isLoggedInWithoutWPCOMCredentials(siteID) || isSiteJetpackJCPConnected(siteID) {
            remote.updateProductIDToWordPressSite(siteID: siteID, productID: productID, mediaID: mediaID) { result in
                onCompletion(result.map { $0.toMedia() })
            }
        } else {
            remote.updateProductID(siteID: siteID, productID: productID, mediaID: mediaID, completion: onCompletion)
        }
    }
}

// MARK: Helpers
//
private extension MediaStore {
    func isLoggedInWithoutWPCOMCredentials(_ siteID: Int64) -> Bool {
        // We check the site ID and assume that we don't have WPCOM creds if the site ID is `-1`
        siteID == WooConstants.placeholderSiteID
    }

    func isSiteJetpackJCPConnected(_ siteID: Int64) -> Bool {
        guard let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() else {
            return false
        }
        return site.isJetpackCPConnected
    }

    @MainActor
    func export(image: UIImage) async throws -> UploadableMedia {
        try await withCheckedThrowingContinuation { continuation in
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                continuation.resume(throwing: MediaActionError.unknown)
                return
            }

            // Hands off the image export to a shared image writer.
            let exporter = MediaImageExporter(data: imageData,
                                              filename: nil,
                                              typeHint: nil,
                                              options: MediaImageExportOptions(maximumImageSize: 3000,
                                                                               imageCompressionQuality: 0.85,
                                                                               stripsGeoLocationIfNeeded: true),
                                              mediaDirectoryType: .uploads)
            exporter.export { uploadableMedia, error in
                guard let uploadableMedia, error == nil else {
                    continuation.resume(throwing: MediaActionError.unknown)
                    return
                }
                continuation.resume(returning: uploadableMedia)
            }
        }
    }
}

public enum MediaActionError: Error {
    case unexpectedMediaCount(count: Int)
    case unknown
}

extension WordPressMedia {
    /// Converts a `WordPressMedia` to `Media`.
    func toMedia() -> Media {
        .init(mediaID: mediaID,
              date: date,
              fileExtension: fileExtension,
              filename: details?.fileName ?? "",
              mimeType: mimeType,
              src: src,
              thumbnailURL: details?.sizes["thumbnail"]?.src,
              name: slug,
              alt: alt,
              height: details?.height,
              width: details?.width)
    }

    private var fileExtension: String {
        guard let fileName = details?.fileName else {
            return ""
        }
        return URL(fileURLWithPath: fileName).pathExtension
    }
}
