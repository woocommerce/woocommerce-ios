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
    // Input fields actions
    func handleDownloadLimitChange(_ downloadLimit: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleDownloadExpiryChange(_ downloadExpiry: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)

    // Navigation actions
    func completeUpdating(onCompletion: ProductDownloadSettingsViewController.Completion)
    func hasUnsavedChanges() -> Bool
}

/// Provides view data for downloadable file settings, and handles init/UI/navigation actions needed in product download settings screen.
///
final class ProductDownloadSettingsViewModel: ProductDownloadSettingsViewModelOutput {
    private let product: ProductFormDataModel

    // Editable data
    //
    private(set) var downloadLimit: Int64
    private(set) var downloadExpiry: Int64

    init(product: ProductFormDataModel) {
        self.product = product
        downloadLimit = product.downloadLimit
        downloadExpiry = product.downloadExpiry
    }

    var sections: [Section] {
        let limitSection = Section(footer: Localization.downloadLimitFooter, rows: [.limit])
        let expirySection = Section(footer: Localization.downloadExpiryFooter, rows: [.expiry])

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

        if downloadLimit?.isEmpty == true {
            self.downloadLimit = -1
            onValidation(isChangesValid(), true)
            return
        }

        guard let downloadLimit = downloadLimit, let downloadLimit_unwrapped = Int64(downloadLimit), downloadLimit_unwrapped >= 0 else {
            self.downloadLimit = -2
            onValidation(isChangesValid(), true)
            return
        }
        self.downloadLimit = downloadLimit_unwrapped
        onValidation(isChangesValid(), false)
    }

    func handleDownloadExpiryChange(_ downloadExpiry: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        if downloadExpiry?.isEmpty == true {
            self.downloadExpiry = -1
            onValidation(isChangesValid(), true)
            return
        }

        guard let downloadExpiry = downloadExpiry, let downloadExpiry_unwrapped = Int64(downloadExpiry), downloadExpiry_unwrapped >= 0 else {
            self.downloadExpiry = -2
            onValidation(isChangesValid(), true)
            return
        }

        self.downloadExpiry = downloadExpiry_unwrapped
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
        return downloadLimit != product.downloadLimit || downloadExpiry != product.downloadExpiry
    }
}

// MARK: - Convenience Methods
//
private extension ProductDownloadSettingsViewModel {
    func isChangesValid() -> Bool {
        // We consider valid values: -1, positive numbers and if at least one new value is different from the previous one
        let downloadLimitIsValid = downloadLimit == -1 || downloadLimit >= 0
        let downloadExpiryIsValid = downloadExpiry == -1 || downloadExpiry >= 0
        let isDownloadLimitOrDownloadExpiryChanged = downloadLimit != product.downloadLimit || downloadExpiry != product.downloadExpiry
        return downloadLimitIsValid && downloadExpiryIsValid && isDownloadLimitOrDownloadExpiryChanged
    }
}

extension ProductDownloadSettingsViewModel {
    enum Localization {
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
