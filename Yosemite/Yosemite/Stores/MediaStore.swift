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
        case .retrieveMediaLibrary(let connectUsing,
                                   let pageNumber,
                                   let pageSize,
                                   let onCompletion):
            switch connectUsing {
            case .wpcom(let siteID):
                retrieveMediaLibrary(siteID: siteID,
                                     pageNumber: pageNumber,
                                     pageSize: pageSize,
                                     onCompletion: onCompletion)
            case .wporg(let siteURL):
                retrieveMediaLibrary(siteURL: siteURL,
                                     pageNumber: pageNumber,
                                     pageSize: pageSize,
                                     onCompletion: onCompletion)
            }
        case .uploadMedia(let connectUsing,
                          let productID,
                          let mediaAsset,
                          let onCompletion):
            uploadMedia(connectUsing: connectUsing,
                        productID: productID,
                        mediaAsset: mediaAsset,
                        onCompletion: onCompletion)
        case .updateProductID(let connectUsing,
                              let productID,
                              let mediaID,
                              let onCompletion):
            switch connectUsing {
            case .wpcom(let siteID):
                updateProductID(siteID: siteID,
                                productID: productID,
                                mediaID: mediaID,
                                onCompletion: onCompletion)
            case .wporg(let siteURL):
                updateProductID(siteURL: siteURL,
                                productID: productID,
                                mediaID: mediaID,
                                onCompletion: onCompletion)

            }
        }
    }
}

// MARK: Retrieve Media library
//
private extension MediaStore {
    func retrieveMediaLibrary(siteURL: String,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: @escaping (Result<[Media], Error>) -> Void) {
        remote.loadMediaLibraryUsingRestApi(siteURL: siteURL,
                                            pageNumber: pageNumber,
                                            pageSize: pageSize) { result in
            onCompletion(result.map { $0.map { $0.toMedia() } })
        }
    }

    func retrieveMediaLibrary(siteID: Int64,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: @escaping (Result<[Media], Error>) -> Void) {
        if isSiteJetpackJCPConnected(siteID) {
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
}

// MARK: Upload Media
//
private extension MediaStore {
    /// Uploads an exportable media asset to the site's WP Media Library with 2 steps:
    /// 1) Exports the media asset to a uploadable type
    /// 2) Uploads the exported media file to the server
    ///
    func uploadMedia(connectUsing: MediaAction.SiteInfo,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     onCompletion: @escaping (Result<Media, Error>) -> Void) {
        mediaExportService.export(mediaAsset,
                                  onCompletion: { [weak self] (uploadableMedia, error) in
            guard let self = self, let uploadableMedia = uploadableMedia, error == nil else {
                onCompletion(.failure(error ?? MediaActionError.unknown))
                return
            }
            switch connectUsing {
            case .wpcom(let siteID):
                self.uploadMedia(siteID: siteID,
                                 productID: productID,
                                 uploadableMedia: uploadableMedia,
                                 onCompletion: onCompletion)
            case .wporg(let siteURL):
                self.uploadMedia(siteURL: siteURL,
                                 productID: productID,
                                 mediaAsset: mediaAsset,
                                 onCompletion: onCompletion)
            }
        })
    }

    func uploadMedia(siteURL: String,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     onCompletion: @escaping (Result<Media, Error>) -> Void) {
        mediaExportService.export(mediaAsset,
                                  onCompletion: { [weak self] (uploadableMedia, error) in
            guard let self = self, let uploadableMedia = uploadableMedia, error == nil else {
                onCompletion(.failure(error ?? MediaActionError.unknown))
                return
            }
            self.remote.uploadMediaUsingRestApi(siteURL: siteURL,
                                                 productID: productID,
                                                 mediaItems: [uploadableMedia]) { result in
                // Removes local media after the upload API request.
                do {
                    try MediaFileManager().removeLocalMedia(at: uploadableMedia.localURL)
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
        })
    }

    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     uploadableMedia media: UploadableMedia,
                     onCompletion: @escaping (Result<Media, Error>) -> Void) {
        if isSiteJetpackJCPConnected(siteID) {
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
}

// MARK: Update Product ID
//
private extension MediaStore {
    func updateProductID(siteURL: String,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: @escaping (Result<Media, Error>) -> Void) {
        remote.updateProductIDUsingRestApi(siteURL: siteURL, productID: productID, mediaID: mediaID) { result in
            onCompletion(result.map { $0.toMedia() })
        }
    }

    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: @escaping (Result<Media, Error>) -> Void) {
        if isSiteJetpackJCPConnected(siteID) {
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
    func isSiteJetpackJCPConnected(_ siteID: Int64) -> Bool {
        guard let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() else {
            return false
        }
        return site.isJetpackCPConnected
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
