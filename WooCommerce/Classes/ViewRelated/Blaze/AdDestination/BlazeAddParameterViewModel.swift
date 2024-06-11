import Foundation

/// View model for `BlazeAddParameterView`
final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String
    @Published var value: String
    @Published private(set) var hasValidationError: Bool = false
    @Published private(set) var hasCountError: Bool = false

    let remainingCharacters: Int
    let parameter: BlazeAdURLParameter?

    var shouldDisableSaveButton: Bool {
        key.isEmpty || value.isEmpty || hasCountError || hasValidationError
    }

    typealias BlazeAddParameterCompletionHandler = (_ key: String, _ value: String) -> Void
    private let completionHandler: BlazeAddParameterCompletionHandler

    private let cancellationHandler: () -> Void

    init(remainingCharacters: Int,
         parameter: BlazeAdURLParameter? = nil,
         onCancel: @escaping () -> Void,
         onCompletion: @escaping BlazeAddParameterCompletionHandler) {
        self.remainingCharacters = remainingCharacters
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

    func validateInputs() {
        validateParameters()
        validateInputLength()
    }
}

private extension BlazeAddParameterViewModel {
    /// This function validates the URL parameters using String.isValidURL().
    /// As isValidURL() needs a full URL, we add Constant.baseURLForValidation as prefix.
    func validateParameters() {
        let url = "\(Constant.baseURLForValidation)\(key)=\(value)"
        hasValidationError = !url.isValidURL()
    }

    func validateInputLength() {
        let totalInputString = key + "=" + value
        hasCountError = remainingCharacters - totalInputString.count < 0
    }
}

private extension BlazeAddParameterViewModel {
    enum Constant {
        static let baseURLForValidation = "https://woocommerce.com/?"
    }
}
