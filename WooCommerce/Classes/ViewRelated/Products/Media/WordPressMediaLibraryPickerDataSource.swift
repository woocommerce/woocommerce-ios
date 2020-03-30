import WPMediaPicker
import Yosemite
import WordPressShared

/// Implements `WPMediaGroup` protocol that represents a collection of media items from WP Media Library to be displayed.
///
final class WordPressMediaLibraryMediaGroup: NSObject, WPMediaGroup {
    private let mediaItems: [Media]

    init(mediaItems: [Media]) {
        self.mediaItems = mediaItems
        super.init()
    }

    func name() -> String {
        return NSLocalizedString("WordPress Media Library", comment: "Navigation bar title for WordPress Media Library image picker")
    }

    func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        return 0
    }

    func cancelImageRequest(_ requestID: WPMediaRequestID) {}

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

/// Implements `WPMediaCollectionDataSource` that provides the media data from WP Media Library for the picker UI.
///
final class WordPressMediaLibraryPickerDataSource: NSObject {
    private let siteID: Int64
    private let syncingCoordinator: SyncingCoordinator

    /// Called when the media data have changed from outside of `loadData` calls. For example, this is called when the media data for the next page return.
    private var onDataChange: WPMediaChangesBlock?

    private var mediaItems: [Media]

    private lazy var mediaGroup: WPMediaGroup = WordPressMediaLibraryMediaGroup(mediaItems: mediaItems)

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

        // Since there is no paging API from the media picker library, this is where we detect whether the last item has been reached via sync coordinator.
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: index)

        return media
    }

    func media(withIdentifier identifier: String) -> WPMediaAsset? {
        return mediaItems.first(where: { "\($0.mediaID)" == identifier })
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
            guard error == nil else {
                failureBlock?(error)
                return
            }
            self?.mediaItems = mediaItems
            successBlock?()
        }
    }

    func mediaTypeFilter() -> WPMediaType {
        return .image
    }

    func ascendingOrdering() -> Bool {
        return true
    }

    func add(_ image: UIImage, metadata: [AnyHashable : Any]?, completionBlock: WPMediaAddedBlock? = nil) {}

    func addVideo(from url: URL, completionBlock: WPMediaAddedBlock? = nil) {}

    func setMediaTypeFilter(_ filter: WPMediaType) {}

    func setAscendingOrdering(_ ascending: Bool) {}

    func setSelectedGroup(_ group: WPMediaGroup) {}
}

extension WordPressMediaLibraryPickerDataSource: SyncingCoordinatorDelegate {
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: ((Bool) -> Void)?) {
        retrieveMedia(pageNumber: pageNumber, pageSize: pageSize) { [weak self] (mediaItems, error) in
            guard error == nil else {
                return
            }
            self?.updateMediaItems(mediaItems, pageNumber: pageNumber, pageSize: pageSize)
        }
    }
}

private extension WordPressMediaLibraryPickerDataSource {
    func retrieveMedia(pageNumber: Int, pageSize: Int, completion: @escaping (_ mediaItems: [Media], _ error: Error?) -> Void) {
        let action = MediaAction.retrieveMediaLibrary(siteID: siteID,
                                                      pageNumber: pageNumber,
                                                      pageSize: pageSize) { (mediaItems, error) in
                                                        guard mediaItems.isEmpty == false else {
                                                            completion([], error)
                                                            return
                                                        }
                                                        completion(mediaItems, nil)
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Appends the new media items to the existing media items.
    ///
    func updateMediaItems(_ newMediaItems: [Media], pageNumber: Int, pageSize: Int) {
        let pageFirstIndex = syncingCoordinator.pageFirstIndex
        let startIndex = (pageNumber - pageFirstIndex) * pageSize
        let startIndexOfTheNextPage = (pageNumber + 1 - pageFirstIndex) * pageSize
        // Since the media data in the given page could be partially full, sets the end index to be the smaller value based on data count or the end of the
        // page index.
        let endIndex = min(startIndex + newMediaItems.count - 1, startIndexOfTheNextPage - 1)

        // In case the data for a given page returns at unexpected timing where the existing media items have changed, returns instead.
        guard mediaItems.count == startIndex else {
            return
        }

        mediaItems += newMediaItems
        onDataChange?(true, [], IndexSet(integersIn: startIndex...endIndex), [], [])
    }
}

private extension WordPressMediaLibraryPickerDataSource {
    enum Constants {
        static let numberOfItemsPerPage: Int = 25
    }
}
