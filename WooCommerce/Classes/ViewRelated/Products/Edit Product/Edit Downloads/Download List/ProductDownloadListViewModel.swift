import Foundation
import Yosemite

/// Provides data needed for downloadable files settings.
///
protocol ProductDownloadListViewModelOutput {
    var downloads: [ProductDownload]? { get }
    var downloadLimit: Int64? { get }
    var downloadExpiry: Int64? { get }
}

/// Handles actions related to the downloadable files settings data.
///
protocol ProductDownloadListActionHandler {
    // Tap actions
    func didTapDownloadableFileFromRow(_ indexPath: IndexPath)

    // Input field actions
    func handleDownloadsChange(_ downloads: [ProductDownload]?)
    func handleDownloadLimitChange(_ downloadLimit: Int64?)
    func handleDownloadExpiryChange(_ downloadExpiry: Int64?)

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadListViewController.Completion)
    func hasUnsavedChanges() -> Bool

    // Convenience Methodes
    @discardableResult
    func remove(at index: Int) -> ProductDownload?
    @discardableResult
    func item(at index: Int) -> ProductDownload?
    func insert(_ newElement: ProductDownload, at index: Int)
    func count() -> Int
}

/// Error cases that could occur in product downloadable files settings.
///
enum ProductDownloadListError: Error {
    case emptyFileName
    case emptyUrl
}

/// Provides view data for price settings, and handles init/UI/navigation actions needed in product price settings.
///
final class ProductDownloadListViewModel: ProductDownloadListViewModelOutput {
    private let product: ProductFormDataModel

    // Editable data
    //
    private(set) var downloads: [ProductDownload]?
    private(set) var downloadLimit: Int64?
    private(set) var downloadExpiry: Int64?

    init(product: ProductFormDataModel) {
        self.product = product

        downloads = product.downloads
        downloadLimit = product.downloadLimit
        downloadExpiry = product.downloadExpiry
    }

    // MARK: - Convenience Methodes
    func remove(at index: Int) -> ProductDownload? {
        return downloads?.remove(at: index)
    }

    func item(at index: Int) -> ProductDownload? {
        return downloads?[index]
    }

    func insert(_ newElement: ProductDownload, at index: Int) {
        downloads?.insert(newElement, at: index)
    }

    func count() -> Int {
        guard let downloads = downloads else {
            return 0
        }
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
    func handleDownloadsChange(_ downloads: [ProductDownload]?) {
        self.downloads = downloads
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
        let data = ProductDownloadsEditableData(downloads: downloads,
                                                downloadLimit: downloadLimit,
                                                downloadExpiry: downloadExpiry)
        onCompletion(data)
    }

    func hasUnsavedChanges() -> Bool {
        if downloadLimit != product.downloadLimit ||
            downloads?.count != product.downloads.count ||
            downloadExpiry != product.downloadExpiry {
            return true
        }

        if let downloads = downloads {
            for index in 0..<downloads.count {
                let oldDownload = product.downloads[index]
                let newDownload = downloads[index]

                if oldDownload.name != newDownload.name ||
                    oldDownload.fileURL != newDownload.fileURL {
                    return true
                }
            }
        }

        return false
    }
}
