import SwiftUI

/// Hosting controller for `StoreNameSetupView`.
///
final class StoreNameSetupHostingController: UIHostingController<StoreNameSetupView> {

    init(viewModel: StoreNameSetupViewModel) {
        super.init(rootView: StoreNameSetupView(viewModel: viewModel))
        rootView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to set up store name
///
struct StoreNameSetupView: View {

    @ObservedObject private var viewModel: StoreNameSetupViewModel

    /// Triggered when the cancel button is tapped
    var onDismiss: () -> Void = {}

    init(viewModel: StoreNameSetupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField(Localization.placeholder, text: $viewModel.name)
                        .textFieldStyle(.plain)
                    Spacer()
                    Button(action: {
                        viewModel.name = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .secondaryBodyStyle()
                    }
                    .renderedIf(viewModel.name.isNotEmpty)
                }
                .padding(Layout.textFieldPadding)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(Layout.textFieldCornerRadius)

                if let message = viewModel.errorMessage {
                    Text(message)
                        .errorStyle()
                }

                Spacer()
            }
            .padding(.horizontal, Layout.textFieldHorizontalMargin)
            .padding(.top, Layout.textFieldVerticalMargin)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSavingInProgress {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Button(Localization.save) {
                            Task { @MainActor in
                                await viewModel.saveName()
                            }
                        }
                        .disabled(viewModel.shouldEnableSaving == false)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .background(Color(uiColor: .listBackground))
        }
    }
}

private extension StoreNameSetupView {
    enum Layout {
        static let textFieldCornerRadius: CGFloat = 8
        static let textFieldPadding: CGFloat = 16
        static let textFieldHorizontalMargin: CGFloat = 16
        static let textFieldVerticalMargin: CGFloat = 24
    }

    enum Localization {
        static let title = NSLocalizedString("Store name", comment: "Title for the store name screen")
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the store name screen")
        static let save = NSLocalizedString("Save", comment: "Button to save the name in the store name screen")
        static let placeholder = NSLocalizedString("Enter your store name", comment: "Placeholder for the text field on the store name screen")
    }
}

struct StoreNameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        StoreNameSetupView(viewModel: .init(siteID: 123, name: "Test") {})
    }
}
