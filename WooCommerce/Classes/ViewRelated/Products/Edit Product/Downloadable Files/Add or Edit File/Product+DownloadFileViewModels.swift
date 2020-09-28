import Yosemite

extension Product {
    static func createDownloadFileNameViewModel(fileName: String?,
                                                onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        return TitleAndTextFieldTableViewCell.ViewModel(title: ProductDownloadFileViewModel.Strings.fileNameTitle,
                                                        text: fileName,
                                                        placeholder: ProductDownloadFileViewModel.Strings.fileNamePlaceholder,
                                                        textFieldAlignment: .trailing,
                                                        onTextChange: onTextChange)
    }

    static func createDownloadFileUrlViewModel(fileUrl: String?,
                                               onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        return TitleAndTextFieldTableViewCell.ViewModel(title: ProductDownloadFileViewModel.Strings.urlTitle,
                                                        text: fileUrl,
                                                        placeholder: ProductDownloadFileViewModel.Strings.urlPlaceholder,
                                                        keyboardType: .URL,
                                                        textFieldAlignment: .trailing,
                                                        onTextChange: onTextChange)
    }
}
