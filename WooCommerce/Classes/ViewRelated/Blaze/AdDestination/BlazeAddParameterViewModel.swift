import Foundation

/// View model for `BlazeAddParameterView`
final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String
    @Published var value: String
    @Published var hasValidationError: Bool = false
    @Published var hasCountError: Bool = false

    let remainingCharacters: Int
    let isNotFirstParameter: Bool
    let parameter: BlazeAdURLParameter?

    var shouldDisableSaveButton: Bool {
        key.isEmpty || value.isEmpty || hasCountError || hasValidationError
    }

    typealias BlazeAddParameterCompletionHandler = (_ key: String, _ value: String) -> Void
    private let completionHandler: BlazeAddParameterCompletionHandler

    private let cancellationHandler: () -> Void

    init(remainingCharacters: Int,
         isNotFirstParameter: Bool = true,
         parameter: BlazeAdURLParameter? = nil,
         onCancel: @escaping () -> Void,
         onCompletion: @escaping BlazeAddParameterCompletionHandler) {
        self.remainingCharacters = remainingCharacters
        self.isNotFirstParameter = isNotFirstParameter
        self.parameter = parameter
        self.cancellationHandler = onCancel
        self.completionHandler = onCompletion

        key = parameter?.key ?? ""
        value = parameter?.value ?? ""
    }

    func didTapCancel() {
        cancellationHandler()
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
        // For adding or editing a new parameter, the two inputs are to be combined to be "key=value".
        // However, for adding or editing 2nd or more parameters, the input becomes "&key=value" due to how URL parameter work.
        let totalInputString = (isNotFirstParameter ? "&" : "") + key + "=" + value

        hasCountError = remainingCharacters - totalInputString.count <= 0
    }
}

private extension BlazeAddParameterViewModel {
    enum Constant {
        static let baseURLForValidation = "https://woo.com/?key="
    }
}
