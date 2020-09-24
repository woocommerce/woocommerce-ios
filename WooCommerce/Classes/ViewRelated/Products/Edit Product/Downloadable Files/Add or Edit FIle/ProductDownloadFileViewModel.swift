import Foundation
import Yosemite

/// Provides data needed for file settings.
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

/// Handles actions related to the file settings data.
///
protocol ProductDownloadFileActionHandler {
    // Input field actions
    func handleFileNameChange(_ fileName: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleFileUrlChange(_ fileURL: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadFileViewController.Completion, onError: (ProductDownloadFileError) -> Void)
    func hasUnsavedChanges() -> Bool
}

/// Error cases that could occur in product download file settings.
///
enum ProductDownloadFileError: Error {
    case emptyFileName
    case emptyFileUrl
    case invalidFileUrl
}

/// Provides view data for downloadable file, and handles init/UI/navigation actions needed in product downloadable file settings.
///
final class ProductDownloadFileViewModel: ProductDownloadFileViewModelOutput {
    private let product: ProductFormDataModel
    private let downloadableFileIndex: Int

    // Editable data
    //
    private(set) var fileName: String?
    private(set) var fileURL: String?
    private(set) var fileID: String?
    private(set) var formType: ProductDownloadFileViewController.FormType

    // Validation
    private var fileNameIsValid: Bool = false
    private var fileUrlIsValid: Bool = false
    private lazy var throttler: Throttler = Throttler(seconds: 0.5)

    init(product: ProductFormDataModel,
         downloadFileIndex: Int = -1,
         formType: ProductDownloadFileViewController.FormType) {
        self.product = product
        self.downloadableFileIndex = downloadFileIndex
        self.formType = formType

        if downloadFileIndex >= 0 {
            let file = product.downloadableFiles[downloadFileIndex]
            fileName = file.name
            fileURL = file.fileURL
            fileID = file.downloadID
        }
    }

    var sections: [Section] {
        let nameSection = Section(footer: Strings.fileNameFooter, rows: [.name])
        let urlSection = Section(footer: Strings.urlFooter, rows: [.url])

        switch product {
        case is EditableProductModel:
            return [
                urlSection,
                nameSection
            ]
        default:
            fatalError("Unsupported product type: \(product)")
        }
    }
}

// MARK: - UI changes
//
extension ProductDownloadFileViewModel: ProductDownloadFileActionHandler {
    func handleFileNameChange(_ fileName: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        self.fileName = fileName

        let newValue = self.fileName
        var oldValue: String?
        if downloadableFileIndex >= 0 {
            oldValue = product.downloadableFiles[downloadableFileIndex].name
        }

        guard newValue != oldValue else {
            fileNameIsValid = false
            onValidation(fileNameIsValid || fileUrlIsValid, true)
            return
        }

        if newValue?.isEmpty == false {
            fileNameIsValid = true
        } else {
            fileNameIsValid = false
        }

        onValidation(isChangesValid(), false)
    }

    func handleFileUrlChange(_ fileURL: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        self.fileURL = fileURL

        let newValue = self.fileURL
        var oldValue: String?
        if downloadableFileIndex >= 0 {
            oldValue = product.downloadableFiles[downloadableFileIndex].fileURL
        }

        guard newValue != oldValue else {
            fileUrlIsValid = false
            onValidation(fileNameIsValid || fileUrlIsValid, true)
            return
        }

        if newValue?.isValidURL() == true && newValue?.isEmpty == false {
            fileUrlIsValid = true
        } else {
            fileUrlIsValid = false
        }

        onValidation(isChangesValid(), false)
    }

    // MARK: - Navigation actions

    func completeUpdating(onCompletion: ProductDownloadFileViewController.Completion,
                          onError: (ProductDownloadFileError) -> Void) {
        if isChangesValid() {
            onCompletion(fileName, fileURL, fileID, hasUnsavedChanges())
        } else if !fileUrlIsValid {
            onError(.invalidFileUrl)
        } else if !fileNameIsValid {
            onError(.emptyFileName)
        }
        return
    }

    func hasUnsavedChanges() -> Bool {
        return isChangesValid()
    }
}

// MARK: - Convenience Methodes
//
private extension ProductDownloadFileViewModel {
    func isChangesValid() -> Bool {
        switch formType {
        case .add:
            return fileUrlIsValid
        case .edit:
            return fileNameIsValid || fileUrlIsValid
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
