import SwiftUI

final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String = ""
    @Published var value: String = ""
    @Published var hasValidationError: Bool = false
    @Published var hasCountError: Bool = false

    let remainingCharacters: Int
    let isFirstParameter: Bool

    var totalInputLength: Int {
        (isFirstParameter ? 0 : "&".count) + key.count + "=".count + value.count
    }

    var shouldDisableSaveButton: Bool {
        key.isEmpty || value.isEmpty || hasCountError || hasValidationError
    }

    typealias BlazeAddParameterCompletionHandler = (_ key: String, _ value: String) -> Void
    private let completionHandler: BlazeAddParameterCompletionHandler

    init(remainingCharacters: Int,
         isFirstParameter: Bool = true,
         onCompletion: @escaping BlazeAddParameterCompletionHandler) {
        self.remainingCharacters = remainingCharacters
        self.isFirstParameter = isFirstParameter
        self.completionHandler = onCompletion
    }

    // todo: use this in view
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


/// View for adding a parameter to a Blaze campaign's URL.
///
struct BlazeAddParameterView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var viewModel: BlazeAddParameterViewModel


    init(viewModel: BlazeAddParameterViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text(Localization.keyTitle)
                            .frame(width: Layout.keyWidth, alignment: .leading)
                        TextField(Localization.keyLabel, text: $viewModel.key)
                    }
                    .onChange(of: viewModel.key) { newValue in
                        viewModel.validateInput(text: newValue)
                    }

                    HStack {
                        Text(Localization.valueTitle)
                            .frame(width: Layout.keyWidth, alignment: .leading)
                        TextField(Localization.valueLabel, text: $viewModel.value)
                    }
                    .onChange(of: viewModel.value) { newValue in
                        viewModel.validateInput(text: newValue)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: Layout.errorVerticalSpacing) {
                        if viewModel.hasValidationError {
                            Text(Localization.validationError)
                        }
                        if viewModel.hasCountError {
                            Text(Localization.characterCountError)
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                    .foregroundColor(Color(uiColor: .accent))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.save) {
                        viewModel.didTapSave()
                    }
                    .disabled(viewModel.shouldDisableSaveButton)
                }
            }
        }
    }
}

struct BlazeAddParameterView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeAddParameterView(viewModel: BlazeAddParameterViewModel(remainingCharacters: 999) { _, _ in })
    }
}


private extension BlazeAddParameterView {
    enum Layout {
        static let keyWidth: CGFloat = 96
        static let errorVerticalSpacing: CGFloat = 8
    }
    enum Localization {
        static let cancel = NSLocalizedString(
            "blazeAddParameterView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Blaze Add Parameter screen"
        )

        static let title = NSLocalizedString(
            "blazeAddParameterView.title",
            value: "Add Parameter",
            comment: "Title of the Blaze Add Parameter screen"
        )

        static let save = NSLocalizedString(
            "blazeAddParameterView.save",
            value: "Save",
            comment: "Button to save on the Blaze Add Parameter screen"
        )

        static let keyTitle = NSLocalizedString(
            "blazeAddParameterView.keyTitle",
            value: "Key",
            comment: "Title for the Key input on the Blaze Add Parameter screen"
        )

        static let valueTitle = NSLocalizedString(
            "blazeAddParameterView.valueTitle",
            value: "Value",
            comment: "Title for the Value input on the Blaze Add Parameter screen"
        )

        static let keyLabel = NSLocalizedString(
            "blazeAddParameterView.keyLabel",
            value: "Enter parameter key",
            comment: "Label for the Key input on the Blaze Add Parameter screen"
        )

        static let valueLabel = NSLocalizedString(
            "blazeAddParameterView.valueLabel",
            value: "Enter parameter value",
            comment: "Label for the Value input on the Blaze Add Parameter screen"
        )

        static let validationError = NSLocalizedString(
            "blazeAddParameterView.validationError",
            value: "You have entered an invalid character to the parameter. Please remove and try again.",
            comment: "Label for the validation error on the Blaze Add Parameter screen."
        )

        static let characterCountError = NSLocalizedString(
            "blazeAddParameterView.characterCountError",
            value: "The input you have entered is too long. Please shorten and try again.",
            comment: "Label for the character count error on the Blaze Add Parameter screen."
        )
    }
}
