import WPMediaPicker
import Yosemite
import WordPressShared

extension WordPressMediaLibraryPickerDataSource {
    /// Implements `WPMediaGroup` protocol that represents a collection of media items from WP Media Library to be displayed.
    ///
    final class MediaGroup: NSObject, WPMediaGroup {
        private let mediaItems: [CancellableMedia]

        init(mediaItems: [CancellableMedia]) {
            self.mediaItems = mediaItems
            super.init()
        }

        func name() -> String {
            return NSLocalizedString("WordPress Media Library", comment: "Navigation bar title for WordPress Media Library image picker")
        }

        func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
            return 0
        }

        func cancelImageRequest(_ requestID: WPMediaRequestID) {
            // No image is shown for the media group.
        }

        func baseGroup() -> Any {
            return ""
        }

        func identifier() -> String {
            return "group id"
        }

        func numberOfAssets(of mediaType: WPMediaType, completionHandler: WPMediaCountBlock? = nil) -> Int {
            return mediaItems.count
        }
    }
}

/// Implements `WPMediaCollectionDataSource` that provides the media data from WP Media Library for the picker UI.
///
final class WordPressMediaLibraryPickerDataSource: NSObject {
    private let siteID: Int64
    private let syncingCoordinator: SyncingCoordinator

    /// Called when the media data have changed from outside of `loadData` calls. For example, this is called when the media data for the next page return.
    private var onDataChange: WPMediaChangesBlock?

    private var mediaItems: [CancellableMedia]

    private lazy var mediaGroup: WPMediaGroup = MediaGroup(mediaItems: mediaItems)

    init(siteID: Int64) {
        self.siteID = siteID
        mediaItems = []
        syncingCoordinator = SyncingCoordinator(pageSize: Constants.numberOfItemsPerPage)
        super.init()

        syncingCoordinator.delegate = self
    }
}

extension WordPressMediaLibraryPickerDataSource: WPMediaCollectionDataSource {
    func numberOfGroups() -> Int {
        return 1
    }

    func group(at index: Int) -> WPMediaGroup {
        return mediaGroup
    }

    func selectedGroup() -> WPMediaGroup? {
        return mediaGroup
    }

    func numberOfAssets() -> Int {
        return mediaItems.count
    }

    func media(at index: Int) -> WPMediaAsset {
        let media = mediaItems[index]

        // TODO-2073: since there is no paging API from the media picker library, this is where we detect whether the last item has been reached via sync
        // coordinator.
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: index)

        return media
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        mediaItems.first(where: { $0.identifier() == identifier })
    }

    func registerChangeObserverBlock(_ callback: @escaping WPMediaChangesBlock) -> NSObjectProtocol {
        onDataChange = callback
        return NSString()
    }

    func registerGroupChangeObserverBlock(_ callback: @escaping WPMediaGroupChangesBlock) -> NSObjectProtocol {
        // The group never changes
        return NSNull()
    }

    func unregisterChangeObserver(_ blockKey: NSObjectProtocol) {
        onDataChange = nil
    }

    func unregisterGroupChangeObserver(_ blockKey: NSObjectProtocol) {
        // The group never changes
    }

    func loadData(with options: WPMediaLoadOptions, success successBlock: WPMediaSuccessBlock?, failure failureBlock: WPMediaFailureBlock? = nil) {
        syncingCoordinator.resetInternalState()
        retrieveMedia(pageNumber: syncingCoordinator.pageFirstIndex, pageSize: Constants.numberOfItemsPerPage) { [weak self] (mediaItems, error) in
            guard let self = self else {
                return
            }

            guard error == nil else {
                failureBlock?(error)
                return
            }
            self.mediaItems = mediaItems.map { CancellableMedia(media: $0) }
            successBlock?()
        }
    }

    func mediaTypeFilter() -> WPMediaType {
        return .image
    }

    func ascendingOrdering() -> Bool {
        return true
    }

    func add(_ image: UIImage, metadata: [AnyHashable: Any]?, completionBlock: WPMediaAddedBlock? = nil) {}

    func addVideo(from url: URL, completionBlock: WPMediaAddedBlock? = nil) {}

    func setMediaTypeFilter(_ filter: WPMediaType) {}

    func setAscendingOrdering(_ ascending: Bool) {}

    func setSelectedGroup(_ group: WPMediaGroup) {}
}

extension WordPressMediaLibraryPickerDataSource: SyncingCoordinatorDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?) {
        retrieveMedia(pageNumber: pageNumber, pageSize: pageSize) { [weak self] (mediaItems, error) in
            guard let self = self else {
                return
            }
            guard error == nil else {
                return
            }
            self.updateMediaItems(mediaItems, pageNumber: pageNumber, pageSize: pageSize)
        }
    }
}

private extension WordPressMediaLibraryPickerDataSource {
    func retrieveMedia(pageNumber: Int, pageSize: Int, completion: @escaping (_ mediaItems: [Media], _ error: Error?) -> Void) {
        let action = MediaAction.retrieveMediaLibrary(forceWPOrgRestAPI: ServiceLocator.stores.isAuthenticatedWithoutWPCom,
                                                      siteID: siteID,
                                                      pageNumber: pageNumber,
                                                      pageSize: pageSize) { result in
            switch result {
            case .success(let mediaItems):
                completion(mediaItems, nil)
            case .failure(let error):
                completion([], error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Appends the new media items to the existing media items.
    ///
    func updateMediaItems(_ newMediaItems: [Media], pageNumber: Int, pageSize: Int) {
        // If the response contains no new items, there is nothing to update.
        // We return early since the code would generate an invalid range of indices to update otherwise.
        guard newMediaItems.isNotEmpty else {
            return
        }

        let pageFirstIndex = syncingCoordinator.pageFirstIndex
        let mediaStartIndex = (pageNumber - pageFirstIndex) * pageSize
        let mediaStartIndexOfTheNextPage = (pageNumber + 1 - pageFirstIndex) * pageSize
        // Since the media data in the given page could be partially full, sets the end index to be the smaller value based on data count or the end of the
        // page index.
        let mediaEndIndex = min(mediaStartIndex + newMediaItems.count - 1, mediaStartIndexOfTheNextPage - 1)

        // In case the data for a given page returns at unexpected timing where the existing media items have changed, returns instead.
        guard mediaItems.count == mediaStartIndex else {
            return
        }

        mediaItems += newMediaItems.map { CancellableMedia(media: $0) }
        onDataChange?(true, [], IndexSet(integersIn: mediaStartIndex...mediaEndIndex), [], [])
    }
}

private extension WordPressMediaLibraryPickerDataSource {
    enum Constants {
        static let numberOfItemsPerPage: Int = 25
    }
}
