import Yosemite

extension Product {
    static func createDownloadLimitViewModel(downloadLimit: Int64,
                                                onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        let text = downloadLimit >= 0 ? String(downloadLimit) : nil
        return TitleAndTextFieldTableViewCell.ViewModel(title: ProductDownloadSettingsViewModel.Localization.downloadLimitTitle,
                                                        text: text,
                                                        placeholder: ProductDownloadSettingsViewModel.Localization.downloadLimitPlaceholder,
                                                        keyboardType: .numberPad,
                                                        textFieldAlignment: .trailing,
                                                        onTextChange: onTextChange)
    }

    static func createDownloadExpiryViewModel(downloadExpiry: Int64,
                                               onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        let text = downloadExpiry >= 0 ? String(downloadExpiry) : nil
        return TitleAndTextFieldTableViewCell.ViewModel(title: ProductDownloadSettingsViewModel.Localization.downloadExpiryTitle,
                                                        text: text,
                                                        placeholder: ProductDownloadSettingsViewModel.Localization.downloadExpiryPlaceholder,
                                                        keyboardType: .numberPad,
                                                        textFieldAlignment: .trailing,
                                                        onTextChange: onTextChange)
    }
}
