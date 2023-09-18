import SwiftUI

final class AddProductNameWithAIHostingController: UIHostingController<AddProductNameWithAIView> {
    init(viewModel: AddProductNameWithAIViewModel) {
        super.init(rootView: AddProductNameWithAIView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

private extension AddProductNameWithAIHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss Add product name screen")
    }
}

/// View for setting name for a new product with AI.
///
struct AddProductNameWithAIView: View {
    @ObservedObject private var viewModel: AddProductNameWithAIViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var editorIsFocused: Bool

    init(viewModel: AddProductNameWithAIViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: Layout.titleBlockSpacing) {
                    // Title label.
                    Text(Localization.title)
                        .fontWeight(.bold)
                        .titleStyle()

                    // Subtitle label.
                    Text(Localization.subtitle)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()
                }
                .padding(.bottom, Layout.titleBlockBottomPadding)

                VStack(alignment: .leading, spacing: Layout.titleBlockSpacing) {
                    VStack(alignment: .leading, spacing: Layout.editorBlockSpacing) {
                        Text(Localization.productName)
                            .foregroundColor(Color(.label))
                            .subheadlineStyle()

                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 0) {
                                TextEditor(text: $viewModel.productNameContent)
                                    .bodyStyle()
                                    .foregroundColor(.secondary)
                                    .padding(insets: Layout.messageContentInsets)
                                    .frame(minHeight: Layout.minimumEditorHeight, maxHeight: .infinity)
                                    .focused($editorIsFocused)

                                Divider()
                                    .frame(height: Layout.dividerHeight)
                                    .foregroundColor(Color(.separator))

                                suggestNameField
                                    .padding(insets: Layout.suggestButtonInsets)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.brand))
                            )

                            // Placeholder text
                            placeholderText
                        }
                    }

                    usePackagePhoto
                }
            }
            .padding(insets: Layout.insets)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // CTA to continue to next screen.
                continueButton
                    .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension AddProductNameWithAIView {
    var suggestNameField: some View {
        HStack {
            // Suggest a name
            Button {
                viewModel.didTapSuggestName()
            } label: {
                HStack(alignment: .top) {
                    Image(uiImage: .sparklesImage)
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color(.brand))
                        .frame(width: Layout.sparkleIconSize * scale, height: Layout.sparkleIconSize * scale)

                    Text(Localization.suggestName)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.brand))
                        .bodyStyle()
                }
            }
            Spacer()
        }
    }

    var placeholderText: some View {
        Text(Localization.placeholder)
            .foregroundColor(Color(.placeholderText))
            .bodyStyle()
            .padding(insets: Layout.placeholderInsets)
            // Allows gestures to pass through to the `TextEditor`.
            .allowsHitTesting(false)
            .renderedIf(viewModel.productNameContent.isEmpty)
    }

    var usePackagePhoto: some View {
        HStack {
            // Use package photo
            Button {
                viewModel.didTapUsePackagePhoto()
            } label: {
                HStack(alignment: .top, spacing: Layout.UsePackagePhoto.spacing) {
                    Image(systemName: Layout.UsePackagePhoto.cameraSFSymbol)
                        .bodyStyle()

                    Text(Localization.usePackagePhoto)
                        .bodyStyle()
                }
            }
            Spacer()
        }
    }

    var continueButton: some View {
        Button {
            // continue
            editorIsFocused = false
            viewModel.didTapContinue()
        } label: {
            Text(Localization.continueText)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.productNameContent.isEmpty)
    }
}
private extension AddProductNameWithAIView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)

        static let titleBlockBottomPadding: CGFloat = 40

        static let titleBlockSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16

        static let editorBlockSpacing: CGFloat = 8
        static let minimumEditorHeight: CGFloat = 70
        static let cornerRadius: CGFloat = 8
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        static let dividerHeight: CGFloat = 1
        static let sparkleIconSize: CGFloat = 24
        static let suggestButtonInsets: EdgeInsets = .init(top: 11, leading: 16, bottom: 11, trailing: 16)

        enum UsePackagePhoto {
            static let cameraSFSymbol = "camera"
            static let spacing: CGFloat = 8
        }
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Add your product name",
            comment: "Title on the add product name screen."
        )
        static let subtitle = NSLocalizedString(
            "Or, expand your choices by tapping for more name suggestions.",
            comment: "Subtitle on the add product name screen."
        )
        static let productName = NSLocalizedString(
            "Product name",
            comment: "Product name text field's label on the add product name screen."
        )
        static let placeholder = NSLocalizedString(
            "For example, Soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product name field"
        )
        static let suggestName = NSLocalizedString(
            "Suggest a name",
            comment: "Suggest name button on the product name field"
        )
        static let usePackagePhoto = NSLocalizedString(
            "Use package photo (Optional)",
            comment: "Use package photo button on the add product name screen."
        )
        static let continueText = NSLocalizedString(
            "Continue",
            comment: "Continue button on the product name field"
        )
    }
}

struct AddProductNameWithAIView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductNameWithAIView(viewModel: .init(siteID: 123, onUsePackagePhoto: { _ in }, onContinueWithProductName: { _ in }))
    }
}
