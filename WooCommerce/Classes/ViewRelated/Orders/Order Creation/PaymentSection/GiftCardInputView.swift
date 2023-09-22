import SwiftUI

/// Allows the user to enter a gift card code.
struct GiftCardInputView: View {
    @StateObject private var viewModel: GiftCardInputViewModel

    init(viewModel: GiftCardInputViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(Localization.placeholder, text: $viewModel.code)
                        .focused()
                    Button {
                        viewModel.apply()
                    } label: {
                        Text(Localization.apply)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.code.isEmpty)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel, action: {
                        viewModel.cancel()
                    })
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .wooNavigationBarStyle()
        }
    }
}

private extension GiftCardInputView {
    enum Localization {
        static let title = NSLocalizedString("Add Gift Card", comment: "Title of the add gift card screen in the order form.")
        static let placeholder = NSLocalizedString("Enter code", comment: "Placeholder of the gift card code text field in the order form.")
        static let apply = NSLocalizedString("Apply", comment: "Button to apply the gift card code to the order form.")
        static let cancel = NSLocalizedString("Cancel", comment: "Button to cancel entering the gift card code from the order form.")
    }
}

struct GiftCardInputView_Previews: PreviewProvider {
    static var previews: some View {
        GiftCardInputView(viewModel: .init(code: "", addGiftCard: { _ in }, dismiss: {}))
    }
}
