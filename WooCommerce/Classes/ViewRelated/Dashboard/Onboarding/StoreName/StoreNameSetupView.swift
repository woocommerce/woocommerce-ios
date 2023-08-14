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
        NavigationView {
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
                .padding(.horizontal, Layout.textFieldHorizontalMargin)
                .padding(.vertical, Layout.textFieldVerticalMargin)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        // TODO
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.save) {
                        // TODO
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
