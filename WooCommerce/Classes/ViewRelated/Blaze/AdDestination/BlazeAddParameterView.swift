import SwiftUI

final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String = ""
    @Published var value: String = ""

    let remainingCharacters: Int
    let isFirstParameter: Bool

    var totalInputLength: Int {
        (isFirstParameter ? 0 : "&".count) + key.count + "=".count + value.count
    }

    var shouldDisableSaveButton: Bool {
        key.isEmpty || value.isEmpty || remainingCharacters - totalInputLength <= 0
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
                HStack {
                    Text(Localization.keyTitle)
                        .frame(width: Layout.keyWidth, alignment: .leading)
                    TextField(Localization.keyLabel, text: $viewModel.key)
                }

                HStack {
                    Text(Localization.valueTitle)
                        .frame(width: Layout.keyWidth, alignment: .leading)
                    TextField(Localization.valueLabel, text: $viewModel.value)
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

    }
}
