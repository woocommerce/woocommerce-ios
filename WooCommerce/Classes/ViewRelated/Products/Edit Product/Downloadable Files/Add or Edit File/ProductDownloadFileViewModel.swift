import Foundation
import Yosemite

/// Provides data needed for downloadable file settings.
///
protocol ProductDownloadFileViewModelOutput {
    typealias Section = ProductDownloadFileViewController.Section
    typealias Row = ProductDownloadFileViewController.Row
    var sections: [Section] { get }
    var formType: ProductDownloadFileViewController.FormType { get }

    var fileName: String? { get }
    var fileURL: String? { get }
    var fileID: String? { get }
}

/// Handles actions related to downloadable file settings data.
///
protocol ProductDownloadFileActionHandler {
    // Input field actions
    func handleFileNameChange(_ fileName: String?, onValidation: @escaping (_ isValid: Bool) -> Void)
    func handleFileUrlChange(_ fileURL: String?, onValidation: @escaping (_ isValid: Bool) -> Void)

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadFileViewController.Completion)
    func hasUnsavedChanges() -> Bool
}

/// Error cases that could occur in product downloadable file settings.
///
enum ProductDownloadFileError: Error {
    case emptyFileName
    case emptyFileUrl
    case invalidFileUrl
}

/// Provides view data for downloadable file, and handles init/UI/navigation actions needed in product downloadable file settings.
///
final class ProductDownloadFileViewModel: ProductDownloadFileViewModelOutput {
    private let productDownload: ProductDownload?
    private let downloadableFileIndex: Int?

    // Editable data
    //
    private(set) var fileName: String?
    private(set) var fileURL: String?
    private(set) var fileID: String?
    private(set) var formType: ProductDownloadFileViewController.FormType

    init(productDownload: ProductDownload?,
         downloadFileIndex: Int?,
         formType: ProductDownloadFileViewController.FormType) {
        self.productDownload = productDownload
        self.downloadableFileIndex = downloadFileIndex
        self.formType = formType

        fileName = productDownload?.name
        fileURL = productDownload?.fileURL
        fileID = productDownload?.downloadID
    }

    var sections: [Section] {
        let nameSection = Section(footer: Strings.fileNameFooter, rows: [.name])
        let urlSection = Section(footer: Strings.urlFooter, rows: [.url])

        return [
            urlSection,
            nameSection
        ]
    }
}

// MARK: - UI changes
//
extension ProductDownloadFileViewModel: ProductDownloadFileActionHandler {

    func handleFileNameChange(_ fileName: String?, onValidation: @escaping (_ isValid: Bool) -> Void) {
        self.fileName = fileName

        onValidation(isChangesValid())
    }

    func handleFileUrlChange(_ fileURL: String?, onValidation: @escaping (_ isValid: Bool) -> Void) {
        self.fileURL = fileURL

        onValidation(isChangesValid())
    }

    // MARK: - Navigation actions

    func completeUpdating(onCompletion: ProductDownloadFileViewController.Completion) {
        if let fileURL = fileURL, isChangesValid() {
            onCompletion(fileName, fileURL, fileID, hasUnsavedChanges())
        }
        return
    }

    func hasUnsavedChanges() -> Bool {
        return isChangesValid()
    }
}

// MARK: - Convenience Methods
//
private extension ProductDownloadFileViewModel {
    func isChangesValid() -> Bool {
        var fileUrlChanged = false
        var fileNameChanged = false

        guard var newFileURL = self.fileURL,
            newFileURL.isEmpty == false,
            newFileURL.isValidURL() == true else {
                return false
        }
        newFileURL = newFileURL.addHTTPSSchemeIfNecessary()

        switch formType {
        case .add:
            fileUrlChanged = true
            if let newFileName = self.fileName,
                newFileName.isEmpty == false {
                fileNameChanged = true
            }
        case .edit:
            if let oldValue = productDownload?.fileURL, newFileURL != oldValue {
                fileUrlChanged = true
            }

            if let newFileName = self.fileName, let oldValue = productDownload?.name,
                newFileName.isNotEmpty,
                newFileName != oldValue {
                fileNameChanged = true
            }
        }

        guard let urlLastPathComponent = URL(string: newFileURL)?.lastPathComponent,
            urlLastPathComponent.isEmpty == false, urlLastPathComponent.split(separator: ".").count >= 2 else {
                if self.fileName?.isEmpty == false {
                    switch formType {
                    case .add:
                        return fileNameChanged
                    case .edit:
                        return fileUrlChanged || fileNameChanged
                    }
                } else {
                    return false
                }
        }

        switch formType {
        case .add:
            return fileUrlChanged
        case .edit:
            return fileUrlChanged || fileNameChanged
        }
    }
}

extension ProductDownloadFileViewModel {
    enum Strings {
        static let fileNameTitle = NSLocalizedString("File Name",
                                                          comment: "Title of the cell in Product Downloadable File > File Name")
        static let fileNamePlaceholder = NSLocalizedString("File Name",
                                                                comment: "Placeholder of the cell text field in Product Downloadable File")
        static let fileNameFooter = NSLocalizedString("This is the name of the file shown to the customer.",
                                                           comment: "Footer text for Downloadable File Name")
        static let urlTitle = NSLocalizedString("File URL",
                                                     comment: "Title of the cell in Product Downloadable File URL > File URL")
        static let urlPlaceholder = NSLocalizedString("File URL",
                                                           comment: "Placeholder of the cell text field in Product Downloadable File URL")
        static let urlFooter = NSLocalizedString("This is the url of the file which customers will get accessed to. URLs entered should already be encoded.",
                                                      comment: "Footer text for Downloadable File URL")
    }
}
