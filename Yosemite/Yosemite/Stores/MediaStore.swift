import Foundation
import Networking
import Storage

// MARK: - MediaStore
//
public final class MediaStore: Store {
    private lazy var mediaExportService: MediaExportService = DefaultMediaExportService()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(mediaExportService: MediaExportService,
         dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network) {
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
        case .uploadMedia(let siteID, let mediaAsset, let onCompletion):
            uploadMedia(siteID: siteID, mediaAsset: mediaAsset, onCompletion: onCompletion)
        }
    }
}

private extension MediaStore {
    /// Uploads an exportable media asset to the site's WP Media Library with 2 steps:
    /// 1) Exports the media asset to a uploadable type
    /// 2) Uploads the exported media file to the server
    ///
    func uploadMedia(siteID: Int64,
                     mediaAsset: ExportableAsset,
                     onCompletion: @escaping (_ uploadedMedia: Media?, _ error: Error?) -> Void) {
        mediaExportService.export(mediaAsset,
                                  onCompletion: { [weak self] (uploadableMedia, error) in
                                    guard let uploadableMedia = uploadableMedia, error == nil else {
                                        onCompletion(nil, error)
                                        return
                                    }
                                    self?.uploadMedia(siteID: siteID,
                                                      uploadableMedia: uploadableMedia,
                                                      onCompletion: onCompletion)
        })
    }

    func uploadMedia(siteID: Int64,
                     uploadableMedia media: UploadableMedia,
                     onCompletion: @escaping (_ uploadedMedia: Media?, _ error: Error?) -> Void) {
        let remote = MediaRemote(network: network)
        remote.uploadMedia(for: siteID,
                           mediaItems: [media]) { (uploadedMediaItems, error) in
                            // Removes local media after the upload API request.
                            do {
                                try MediaFileManager().removeLocalMedia(at: media.localURL)
                            } catch {
                                onCompletion(nil, error)
                                return
                            }
                            guard let uploadedMedia = uploadedMediaItems?.first, uploadedMediaItems?.count == 1 && error == nil else {
                                onCompletion(nil, error)
                                return
                            }
                            onCompletion(uploadedMedia, nil)
        }
    }
}
