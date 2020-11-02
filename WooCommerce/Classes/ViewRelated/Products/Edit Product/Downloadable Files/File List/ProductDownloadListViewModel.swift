import Foundation
import Yosemite

/// Provides data needed for downloadable files settings.
///
protocol ProductDownloadListViewModelOutput {
    var downloadableFiles: [ProductDownloadDragAndDrop] { get }
    var downloadLimit: Int64 { get }
    var downloadExpiry: Int64 { get }

    // Actions available on the bottom sheet
    var bottomSheetActions: [DownloadableFileSource] { get }

    // Convenience Methods
    @discardableResult
    func remove(at index: Int) -> ProductDownloadDragAndDrop?
    func item(at index: Int) -> ProductDownloadDragAndDrop?
    func insert(_ newElement: ProductDownloadDragAndDrop, at index: Int)
    func append(_ newElement: ProductDownloadDragAndDrop)
    func update(at index: Int, element: ProductDownloadDragAndDrop)
    func count() -> Int
}

/// Handles actions related to the downloadable files settings data.
///
protocol ProductDownloadListActionHandler {

    // Input field actions
    func handleDownloadableFilesChange(_ downloads: [ProductDownload])
    func handleDownloadLimitChange(_ downloadLimit: Int64)
    func handleDownloadExpiryChange(_ downloadExpiry: Int64)

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
    private(set) var downloadableFiles = [ProductDownloadDragAndDrop]()
    private(set) var downloadLimit: Int64
    private(set) var downloadExpiry: Int64

    var bottomSheetActions: [DownloadableFileSource] {
        [.device, .wordPressMediaLibrary, .fileURL]
    }

    init(product: ProductFormDataModel) {
        self.product = product

        downloadableFiles = product.downloadableFiles.map { ProductDownloadDragAndDrop(downloadableFile: $0) }
        downloadLimit = product.downloadLimit
        downloadExpiry = product.downloadExpiry
    }

    // MARK: - ProductDownloadListDataSource Methods
    //
    func remove(at index: Int) -> ProductDownloadDragAndDrop? {
        return index < downloadableFiles.count ? downloadableFiles.remove(at: index) : nil
    }

    func item(at index: Int) -> ProductDownloadDragAndDrop? {
        return downloadableFiles[safe: index]
    }

    func insert(_ newElement: ProductDownloadDragAndDrop, at index: Int) {
        downloadableFiles.insert(newElement, at: index)
    }

    func append(_ newElement: ProductDownloadDragAndDrop) {
        downloadableFiles.append(newElement)
    }

    func update(at index: Int, element: ProductDownloadDragAndDrop) {
        downloadableFiles[index] = element
    }

    func count() -> Int {
        return downloadableFiles.count
    }
}

extension ProductDownloadListViewModel: ProductDownloadListActionHandler {

    // MARK: - UI changes

    // Input field actions
    func handleDownloadableFilesChange(_ downloads: [ProductDownload]) {
        self.downloadableFiles = downloads.map { ProductDownloadDragAndDrop(downloadableFile: $0) }
    }

    func handleDownloadLimitChange(_ downloadLimit: Int64) {
        self.downloadLimit = downloadLimit
    }

    func handleDownloadExpiryChange(_ downloadExpiry: Int64) {
        self.downloadExpiry = downloadExpiry
    }

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadListViewController.Completion) {
        let data = ProductDownloadsEditableData(downloadableFiles: downloadableFiles.map { $0.downloadableFile },
                                                downloadLimit: downloadLimit,
                                                downloadExpiry: downloadExpiry)
        onCompletion(data, hasUnsavedChanges())
    }

    func hasUnsavedChanges() -> Bool {
        if downloadLimit != product.downloadLimit ||
            downloadableFiles.count != product.downloadableFiles.count ||
            downloadExpiry != product.downloadExpiry ||
            downloadableFiles.count != product.downloadableFiles.count {
            return true
        }

        for index in 0..<downloadableFiles.count {
            let oldDownload = product.downloadableFiles[index]
            let newDownload = downloadableFiles[index].downloadableFile

            if oldDownload.name != newDownload.name ||
                oldDownload.fileURL != newDownload.fileURL {
                return true
            }
        }

        return false
    }
}
