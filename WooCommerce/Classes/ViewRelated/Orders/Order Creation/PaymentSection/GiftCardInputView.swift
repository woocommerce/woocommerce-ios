import SwiftUI

/// Allows the user to enter a gift card code.
struct GiftCardInputView: View {
    @StateObject private var viewModel: GiftCardInputViewModel
    @State private var showsScanner: Bool = false

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: GiftCardInputViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        Text(Localization.header)
                            .foregroundColor(.init(uiColor: .text))
                            .subheadlineStyle()
                        HStack {
                            TextField(Localization.placeholder, text: $viewModel.code)
                                .focused()
                                .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
                            Spacer()
                            Button {
                                showsScanner = true
                            } label: {
                                Image(uiImage: .scanImage.withRenderingMode(.alwaysTemplate))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: Constants.scanImageSize * scale)
                                    .foregroundColor(Color(.accent))
                            }
                            .sheet(isPresented: $showsScanner) {
                                GiftCardCodeScannerNavigationView(onCodeScanned: { code in
                                    viewModel.code = code
                                    showsScanner = false
                                }, onClose: {
                                    showsScanner = false
                                })
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(Color(uiColor: .error))
                        }
                    }
                    .padding(Constants.insets)

                    VStack(alignment: .leading, spacing: .zero) {
                        Divider()

                        Button {
                            viewModel.remove()
                        } label: {
                            Text(Localization.remove)
                                .foregroundColor(.init(uiColor: .error))
                        }
                        .foregroundColor(.init(uiColor: .error))
                        .buttonStyle(RoundedBorderedStyle(borderColor: .init(uiColor: .error)))
                        .padding(Constants.insets)
                    }
                    .renderedIf(viewModel.isValid)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel, action: {
                        viewModel.cancel()
                    })
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.apply, action: {
                        viewModel.apply()
                    })
                    .disabled(!viewModel.isValid)
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
        static let header = NSLocalizedString("Gift card code", comment: "Header of the gift card code text field in the order form.")
        static let placeholder = NSLocalizedString("XXXX-XXXX-XXXX-XXXX", comment: "Placeholder of the gift card code text field in the order form.")
        static let apply = NSLocalizedString("Apply", comment: "Button to apply the gift card code to the order form.")
        static let cancel = NSLocalizedString("Cancel", comment: "Button to cancel entering the gift card code from the order form.")
        static let remove = NSLocalizedString("Remove Gift Card", comment: "Button to remove the gift card code from the order form.")
    }

    enum Constants {
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let verticalSpacing: CGFloat = 8
        static let scanImageSize: CGFloat = 24
    }
}

struct GiftCardInputView_Previews: PreviewProvider {
    static var previews: some View {
        GiftCardInputView(viewModel: .init(code: "UU35-T3RE-BSWK-36J4", setGiftCard: { _ in }, dismiss: {}))
        GiftCardInputView(viewModel: .init(code: "", setGiftCard: { _ in }, dismiss: {}))
    }
}
