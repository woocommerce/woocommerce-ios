import Foundation

extension TitleAndTextFieldTableViewCell.ViewModel {
    /// Returns a view model with the same fields except for the state replaced by the given value.
    ///
    func stateUpdated(state: State) -> TitleAndTextFieldTableViewCell.ViewModel {
        return TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                        text: text,
                                                        placeholder: placeholder,
                                                        state: state,
                                                        onTextChange: onTextChange)
    }
}
