import SwiftUI

/// View for adding a parameter to a Blaze campaign's URL.
///
struct BlazeAddParameterView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: BlazeAddParameterViewModel

    init(viewModel: BlazeAddParameterViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.keyTitle)
                            .fixedSize()
                            .frame(width: Layout.keyWidth, alignment: .leading)
                        TextField(Localization.keyLabel, text: $viewModel.key)
                    }
                    .onChange(of: viewModel.key) { _ in
                        viewModel.validateInputs()
                    }

                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.valueTitle)
                            .fixedSize()
                            .frame(width: Layout.keyWidth, alignment: .leading)
                        TextField(Localization.valueLabel, text: $viewModel.value)
                    }
                    .onChange(of: viewModel.value) { _ in
                        viewModel.validateInputs()
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
            .navigationTitle(viewModel.parameter == nil ? Localization.title : Localization.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        viewModel.didTapCancel()
                        dismiss()
                    }
                    .foregroundColor(Color(uiColor: .accent))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.save) {
                        viewModel.didTapSave()
                        dismiss()
                    }
                    .disabled(viewModel.shouldDisableSaveButton)
                }
            }
        }
    }
}

struct BlazeAddParameterView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeAddParameterView(viewModel: BlazeAddParameterViewModel(remainingCharacters: 999,
                                                                    onCancel: { },
                                                                    onCompletion: { _, _ in })
        )
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

        static let editTitle = NSLocalizedString(
            "blazeAddParameterView.editTitle",
            value: "Edit Parameter",
            comment: "Title of the Blaze Add Parameter screen in edit mode"
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
