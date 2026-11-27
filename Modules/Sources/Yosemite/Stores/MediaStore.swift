import Foundation
import Networking
import Storage

// MARK: - MediaStore
//
public final class MediaStore: Store {
    private let remote: MediaRemoteProtocol
    private let mediaExportService: MediaExportService

    override public convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = MediaRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: MediaRemoteProtocol) {
        self.remote = remote
        self.mediaExportService = DefaultMediaExportService()
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
        self.mediaExportService = mediaExportService
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
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
        case .retrieveMedia(let siteID,
                            let mediaID,
                            let onCompletion):
            retrieveMedia(siteID: siteID, mediaID: mediaID, onCompletion: onCompletion)
        case let .retrieveMediaLibrary(siteID, productID, imagesOnly, pageNumber, pageSize, onCompletion):
            retrieveMediaLibrary(siteID: siteID,
                                 productID: productID,
                                 imagesOnly: imagesOnly,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 onCompletion: onCompletion)
        case .uploadMedia(let siteID, let productID, let mediaAsset, let altText, let filename, let onCompletion):
            uploadMedia(siteID: siteID, productID: productID, mediaAsset: mediaAsset, altText: altText, filename: filename, onCompletion: onCompletion)
        case let .uploadFile(siteID, productID, localURL, altText, onCompletion):
            uploadFile(siteID: siteID,
                       productID: productID,
                       localURL: localURL,
                       altText: altText,
                       onCompletion: onCompletion)
        case .updateProductID(let siteID,
                            let productID,
                             let mediaID,
                             let onCompletion):
            updateProductID(siteID: siteID, productID: productID, mediaID: mediaID, onCompletion: onCompletion)
        }
    }
}

private extension MediaStore {
    /// Retrieves single Media item from the site's WP Media Library.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - mediaID: ID of Media to be retrieved
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    func retrieveMedia(siteID: Int64,
                       mediaID: Int64,
                       onCompletion: @escaping (Result<Media, Error>) -> Void) {
        remote.loadMedia(siteID: siteID, mediaID: mediaID) { result in
            onCompletion(result.map { $0.toMedia() })
        }
    }

    func retrieveMediaLibrary(siteID: Int64,
                              productID: Int64? = nil,
                              imagesOnly: Bool,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: @escaping (Result<[Media], Error>) -> Void) {
        remote.loadMediaLibrary(siteID: siteID,
                                productID: productID,
                                imagesOnly: imagesOnly,
                                pageNumber: pageNumber,
                                pageSize: pageSize) { result in
            onCompletion(result.map { $0.map { $0.toMedia() } })
        }
    }

    /// Uploads an exportable media asset to the site's WP Media Library with 2 steps:
    /// 1) Exports the media asset to a uploadable type
    /// 2) Uploads the exported media file to the server
    ///
    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     altText: String?,
                     filename: String?,
                     onCompletion: @escaping @MainActor @Sendable (Result<Media, Error>) -> Void) {
        Task { @MainActor [mediaExportService, remote] in
            do {
                let media = try await mediaExportService.export(mediaAsset, filename: filename, altText: altText)
                let result = await Self.uploadMedia(siteID: siteID, productID: productID, media: media, remote: remote)
                try MediaFileManager().removeLocalMedia(at: media.localURL)
                onCompletion(result)
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    static func uploadMedia(siteID: Int64,
                            productID: Int64,
                            media: UploadableMedia,
                            remote: MediaRemoteProtocol) async -> Result<Media, Error> {
        await withCheckedContinuation { continuation in
            remote.uploadMedia(siteID: siteID, productID: productID, mediaItem: media) { result in
                continuation.resume(returning: result.map { $0.toMedia() })
            }
        }
    }

    func uploadFile(siteID: Int64,
                    productID: Int64,
                    localURL: URL,
                    altText: String?,
                    onCompletion: @escaping @MainActor @Sendable (Result<Media, Error>) -> Void) {
        let media = UploadableMedia(localURL: localURL,
                                    filename: localURL.lastPathComponent,
                                    mimeType: localURL.mimeTypeForPathExtension,
                                    altText: altText)
        Task { @MainActor [remote] in
            let result = await Self.uploadMedia(siteID: siteID, productID: productID, media: media, remote: remote)
            onCompletion(result)
        }
    }

    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: @escaping (Result<Media, Error>) -> Void) {
        remote.updateProductID(siteID: siteID, productID: productID, mediaID: mediaID) { result in
            onCompletion(result.map { $0.toMedia() })
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
              filename: details?.fileName ?? title?.rendered ?? slug,
              mimeType: mimeType,
              src: src,
              thumbnailURL: details?.sizes?["thumbnail"]?.src,
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
