import Foundation
import Yosemite

/// Provides data needed for download settings.
///
protocol ProductDownloadSettingsViewModelOutput {
    typealias Section = ProductDownloadSettingsViewController.Section
    typealias Row = ProductDownloadSettingsViewController.Row
    var sections: [Section] { get }

    var downloadLimit: Int64 { get }
    var downloadExpiry: Int64 { get }
}

/// Handles actions related to the download settings data.
///
protocol ProductDownloadSettingsActionHandler {
    // Input field actions
    func handleDownloadLimitChange(_ downloadLimit: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleDownloadExpiryChange(_ downloadExpiry: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadSettingsViewController.Completion)
    func hasUnsavedChanges() -> Bool
}

/// Provides view data for downloadable file download, and handles init/UI/navigation actions needed in product download settings.
///
final class ProductDownloadSettingsViewModel: ProductDownloadSettingsViewModelOutput {
    private let product: ProductFormDataModel

    // Editable data
    //
    private(set) var downloadLimit: Int64
    private(set) var downloadExpiry: Int64

    // Validation
    private var downloadLimitIsValid: Bool = false
    private var downloadExpiryIsValid: Bool = false

    init(product: ProductFormDataModel) {
        self.product = product
        self.downloadLimit = product.downloadLimit
        self.downloadExpiry = product.downloadExpiry
        downloadLimitIsValid = self.downloadLimit >= 0 ? true : false
        downloadExpiryIsValid = self.downloadExpiry >= 0 ? true : false
    }

    var sections: [Section] {
        let limitSection = Section(footer: Strings.downloadLimitFooter, rows: [.limit])
        let expirySection = Section(footer: Strings.downloadExpiryFooter, rows: [.expiry])

        switch product {
        case is EditableProductModel:
            return [
                limitSection,
                expirySection
            ]
        default:
            fatalError("Unsupported product type: \(product)")
        }
    }
}

// MARK: - UI changes
//
extension ProductDownloadSettingsViewModel: ProductDownloadSettingsActionHandler {
    func handleDownloadLimitChange(_ downloadLimit: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        guard let downloadLimit = downloadLimit, let downloadLimit_unwrapped = Int64(downloadLimit), downloadLimit_unwrapped >= 0 else {
            downloadLimitIsValid = false
            self.downloadLimit = -1
            onValidation(isChangesValid(), true)
            return
        }
        self.downloadLimit = downloadLimit_unwrapped
        let newValue = self.downloadLimit
        let oldValue = product.downloadLimit

        guard newValue != oldValue else {
            downloadLimitIsValid = false
            onValidation(isChangesValid(), true)
            return
        }
        downloadLimitIsValid = true
        onValidation(isChangesValid(), false)
    }

    func handleDownloadExpiryChange(_ downloadExpiry: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        guard let downloadExpiry = downloadExpiry, let downloadExpiry_unwrapped = Int64(downloadExpiry), downloadExpiry_unwrapped >= 0 else {
            downloadExpiryIsValid = false
            self.downloadExpiry = -1
            onValidation(isChangesValid(), true)
            return
        }
        self.downloadExpiry = downloadExpiry_unwrapped
        let newValue = self.downloadExpiry
        let oldValue = product.downloadExpiry

        guard newValue != oldValue else {
            downloadExpiryIsValid = false
            onValidation(isChangesValid(), true)
            return
        }
        downloadExpiryIsValid = true
        onValidation(isChangesValid(), false)
    }

    // MARK: - Navigation actions

    func completeUpdating(onCompletion: ProductDownloadSettingsViewController.Completion) {
        if isChangesValid() {
            onCompletion(downloadLimit, downloadExpiry, hasUnsavedChanges())
        }
        return
    }

    func hasUnsavedChanges() -> Bool {
        return isChangesValid()
    }
}

// MARK: - Convenience Methods
//
private extension ProductDownloadSettingsViewModel {
    func isChangesValid() -> Bool {
        return downloadLimitIsValid || downloadExpiryIsValid
    }
}

extension ProductDownloadSettingsViewModel {
    enum Strings {
        static let downloadLimitTitle = NSLocalizedString("Download limit",
                                                          comment: "Title of the cell in Product Download limit > Download limit")
        static let downloadLimitPlaceholder = NSLocalizedString("No limit",
                                                                comment: "Placeholder of the cell text field in Download limit")
        static let downloadLimitFooter = NSLocalizedString("Enter the number of time file can be downloaded or leave blank for unlimited downloads",
                                                           comment: "Footer text for Downloadable Limit")
        static let downloadExpiryTitle = NSLocalizedString("Download expiration",
                                                     comment: "Title of the cell in Product Download Expiration > Download expiration")
        static let downloadExpiryPlaceholder = NSLocalizedString("No expiration",
                                                           comment: "Placeholder of the cell text field in Download expiration")
        static let downloadExpiryFooter = NSLocalizedString("Enter the number of days before a download link expires, or leave blank if never it expires",
                                                            comment: "Footer text for Download Expiration")
    }
}
