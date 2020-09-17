import Foundation
import Yosemite

/// Provides data needed for downloadable files settings.
///
protocol ProductDownloadListViewModelOutput {
    var downloads: [ProductDownloadDnD] { get }
    var downloadLimit: Int64? { get }
    var downloadExpiry: Int64? { get }

        // Convenience Methodes
    @discardableResult
    func remove(at index: Int) -> ProductDownloadDnD?
    @discardableResult
    func item(at index: Int) -> ProductDownloadDnD?
    func insert(_ newElement: ProductDownloadDnD, at index: Int)
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

protocol ProductDownloadListDataSource {

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
    private(set) var downloads = [ProductDownloadDnD]()
    private(set) var downloadLimit: Int64?
    private(set) var downloadExpiry: Int64?

    init(product: ProductFormDataModel) {
        self.product = product

        downloads = populateDataSource(product.downloads)
        downloadLimit = product.downloadLimit
        downloadExpiry = product.downloadExpiry
    }

    // MARK: - ProductDownloadListDataSource Methodes
    //
    func remove(at index: Int) -> ProductDownloadDnD? {
        return downloads.remove(at: index)
    }

    func item(at index: Int) -> ProductDownloadDnD? {
        return downloads[index]
    }

    func insert(_ newElement: ProductDownloadDnD, at index: Int) {
        downloads.insert(newElement, at: index)
    }

    func count() -> Int {
        return downloads.count
    }

    func allDownloadableFiles(_ downloadableFiles: [ProductDownloadDnD]) -> [ProductDownload] {
        var downloads = [ProductDownload]()
        for download in downloadableFiles {
            downloads.append(download.download)
        }
        return downloads
    }

    func populateDataSource(_ downloads: [ProductDownload]) -> [ProductDownloadDnD] {
        var datasource = [ProductDownloadDnD]()
        for download in downloads {
            datasource.append(ProductDownloadDnD(download: download))
        }
        return datasource
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
        self.downloads = populateDataSource(downloads)
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
        let data = ProductDownloadsEditableData(downloads: allDownloadableFiles(downloads),
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

        for index in 0..<downloads.count {
            let oldDownload = product.downloads[index]
            let newDownload = downloads[index]

            if oldDownload.name != newDownload.download.name ||
                oldDownload.fileURL != newDownload.download.fileURL {
                return true
            }
        }
        return false
    }
}
