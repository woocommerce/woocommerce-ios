import Foundation

/// View model for `BlazeAddParameterView`
final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String
    @Published var value: String
    @Published var hasValidationError: Bool = false
    @Published var hasCountError: Bool = false

    typealias Parameter =  BlazeAdDestinationSettingViewModel.BlazeAdURLParameter
    let remainingCharacters: Int
    let isNotFirstParameter: Bool
    let parameter: Parameter?

    // For adding or editing a new parameter, the two inputs are to be combined to be "key=value".
    // However, for adding or editing 2nd or more parameters, the input becomes "&key=value" due to how URL parameter work.
    var totalInputLength: Int {
        let inputString = (isNotFirstParameter ? "&" : "") + key + "=" + value
        return inputString.count
    }

    var shouldDisableSaveButton: Bool {
        key.isEmpty || value.isEmpty || hasCountError || hasValidationError
    }

    typealias BlazeAddParameterCompletionHandler = (_ key: String, _ value: String) -> Void
    private let completionHandler: BlazeAddParameterCompletionHandler

    init(remainingCharacters: Int,
         isNotFirstParameter: Bool = true,
         parameter: Parameter? = nil,
         onCompletion: @escaping BlazeAddParameterCompletionHandler) {
        self.remainingCharacters = remainingCharacters
        self.isNotFirstParameter = isNotFirstParameter
        self.parameter = parameter
        self.completionHandler = onCompletion

        key = parameter?.key ?? ""
        value = parameter?.value ?? ""
    }

    func didTapSave() {
        completionHandler(key, value)
    }

    func validateInput(text: String) {
        validateParameter(text: text)
        validateInputLength()
    }

    /// This function validates the URL parameters using String.isValidURL().
    /// It requires a full URL, thus Constant.baseURLForValidation is added.
    /// The constant uses "?key=", but it's also used to validate parameter keys, as they both follow the same validation rule.
    ///
    private func validateParameter(text: String) {
        let url = Constant.baseURLForValidation + text
        hasValidationError = !url.isValidURL()
    }

    private func validateInputLength() {
        hasCountError = remainingCharacters - totalInputLength <= 0
    }
}

private extension BlazeAddParameterViewModel {
    enum Constant {
        static let baseURLForValidation = "https://woo.com/?key="
    }
}
