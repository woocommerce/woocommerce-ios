import Foundation

final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String
    @Published var value: String
    @Published var hasValidationError: Bool = false
    @Published var hasCountError: Bool = false

    typealias Parameter =  BlazeAdDestinationSettingViewModel.BlazeAdURLParameter
    let remainingCharacters: Int
    let isNotFirstParameter: Bool
    let parameter: Parameter?

    // For adding or editing a new parameter, the input becomes "key=value"
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

    /// To keep it simple, the existing String.isValidURL() is used to validate the parameter key or value.
    /// Since that function requires a full URL, Constant.baseURLForValidation is used to build it.
    /// The constant uses "?key=" even though this function is used to validate parameter key too,
    /// but that's OK because key and value strings has the same validation rule.
    ///
    private func validateParameter(text: String) {
        let url = Constant.baseURLForValidation + text
        if url.isValidURL() {
            hasValidationError = false
        } else {
            hasValidationError = true
        }
    }

    private func validateInputLength() {
        if remainingCharacters - totalInputLength <= 0 {
            hasCountError = true
        } else {
            hasCountError = false
        }
    }
}

private extension BlazeAddParameterViewModel {
    enum Constant {
        static let baseURLForValidation = "https://woo.com/?key="
    }
}
