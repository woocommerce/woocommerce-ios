import Foundation
import Yosemite

/// Provides data needed for downloadable files settings.
///
protocol ProductDownloadListViewModelOutput {
    var downloads: [ProductDownloadDragAndDrop] { get }
    var downloadLimit: Int64? { get }
    var downloadExpiry: Int64? { get }

        // Convenience Methodes
    @discardableResult
    func remove(at index: Int) -> ProductDownloadDragAndDrop?
    func item(at index: Int) -> ProductDownloadDragAndDrop?
    func insert(_ newElement: ProductDownloadDragAndDrop, at index: Int)
    func count() -> Int
}

/// Handles actions related to the downloadable files settings data.
///
protocol ProductDownloadListActionHandler {
    // Tap actions
    func didTapDownloadableFileFromRow(_ indexPath: IndexPath)

    // Input field actions
    func handleDownloadsChange(_ downloads: [ProductDownload])
    func handleDownloadLimitChange(_ downloadLimit: Int64?)
    func handleDownloadExpiryChange(_ downloadExpiry: Int64?)

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadListViewController.Completion)
    func hasUnsavedChanges() -> Bool
}

/// Error cases that could occur in product downloadable files settings.
///
enum ProductDownloadListError: Error {
    case emptyFileName
    case emptyUrl
}

/// Provides view data for downloadable files settings, and handles init/UI/navigation actions needed in product downloadable files settings.
///
final class ProductDownloadListViewModel: ProductDownloadListViewModelOutput {
    private let product: ProductFormDataModel

    // Editable data
    //
    private(set) var downloads = [ProductDownloadDragAndDrop]()
    private(set) var downloadLimit: Int64?
    private(set) var downloadExpiry: Int64?

    init(product: ProductFormDataModel) {
        self.product = product

        downloads = product.downloads.map { ProductDownloadDragAndDrop(download: $0) }
        downloadLimit = product.downloadLimit
        downloadExpiry = product.downloadExpiry
    }

    // MARK: - ProductDownloadListDataSource Methodes
    //
    func remove(at index: Int) -> ProductDownloadDragAndDrop? {
        return downloads.remove(at: index)
    }

    func item(at index: Int) -> ProductDownloadDragAndDrop? {
        return downloads[index]
    }

    func insert(_ newElement: ProductDownloadDragAndDrop, at index: Int) {
        downloads.insert(newElement, at: index)
    }

    func count() -> Int {
        return downloads.count
    }
}

extension ProductDownloadListViewModel: ProductDownloadListActionHandler {

    // MARK: - Tap actions

    func didTapDownloadableFileFromRow(_ indexPath: IndexPath) {
        //TODO: Show respective file in a new window
    }

    // MARK: - UI changes

    // Input field actions
    func handleDownloadsChange(_ downloads: [ProductDownload]) {
        self.downloads = downloads.map { ProductDownloadDragAndDrop(download: $0) }
    }

    func handleDownloadLimitChange(_ downloadLimit: Int64?) {
        self.downloadLimit = downloadLimit
    }

    func handleDownloadExpiryChange(_ downloadExpiry: Int64?) {
        self.downloadExpiry = downloadExpiry
    }

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadListViewController.Completion) {
        //TODO: Perform data validation as necessary
        let data = ProductDownloadsEditableData(downloads: downloads.map { $0.download },
                                                downloadLimit: downloadLimit,
                                                downloadExpiry: downloadExpiry)
        onCompletion(data)
    }

    func hasUnsavedChanges() -> Bool {
        if downloadLimit != product.downloadLimit ||
            downloads.count != product.downloads.count ||
            downloadExpiry != product.downloadExpiry {
            return true
        }

        //TODO: Check if the data has been changed and return accordingly.

        return false
    }
}
