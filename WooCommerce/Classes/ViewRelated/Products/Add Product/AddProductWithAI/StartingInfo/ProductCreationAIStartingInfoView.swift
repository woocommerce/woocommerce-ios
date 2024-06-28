import SwiftUI

/// View for entering keywords or selecting package photo for creating a new product with AI.
///
struct ProductCreationAIStartingInfoView: View {
    @ObservedObject private var viewModel: ProductCreationAIStartingInfoViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var editorIsFocused: Bool

    private let onUsePackagePhoto: (String?) -> Void
    private let onContinueWithFeatures: (String) -> Void

    init(viewModel: ProductCreationAIStartingInfoViewModel,
         onUsePackagePhoto: @escaping (String?) -> Void,
         onContinueWithFeatures: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onUsePackagePhoto = onUsePackagePhoto
        self.onContinueWithFeatures = onContinueWithFeatures
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
                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $viewModel.features)
                                    .bodyStyle()
                                    .foregroundColor(.secondary)
                                    .padding(insets: Layout.messageContentInsets)
                                    .frame(minHeight: Layout.minimumEditorHeight, maxHeight: .infinity)
                                    .focused($editorIsFocused)

                                // Placeholder text
                                placeholderText
                            }

                            Divider()
                                .frame(height: Layout.dividerHeight)
                                .foregroundColor(Color(.separator))

                            readTextFromPhotoButton
                                .padding(insets: Layout.readTextFromPhotoButtonInsets)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(editorIsFocused ? Color(.brand) : Color(.separator))
                        )
                    }
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

private extension ProductCreationAIStartingInfoView {
    var readTextFromPhotoButton: some View {
        HStack {
            Button {
                viewModel.didTapReadTextFromPhoto()
                // TODO: Launch photo selection flow
            } label: {
                HStack(alignment: .center, spacing: Layout.UsePackagePhoto.spacing) {
                    Image(systemName: Layout.UsePackagePhoto.cameraSFSymbol)
                        .renderingMode(.template)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
                        .bodyStyle()
                        .padding(Layout.UsePackagePhoto.padding)

                    Text(Localization.readTextFromPhoto)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentColor)
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
            .renderedIf(viewModel.features.isEmpty)
    }

    var continueButton: some View {
        Button {
            // continue
            editorIsFocused = false
            viewModel.didTapContinue()
            onContinueWithFeatures(viewModel.features)
        } label: {
            Text(Localization.continueText)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.features.isEmpty)
    }
}

private extension ProductCreationAIStartingInfoView {
    struct PackagePhotoView: View {
        @ScaledMetric private var scale: CGFloat = 1.0

        let image: UIImage

        let onTapViewPhoto: () -> Void
        let onTapReplacePhoto: () -> Void
        let onTapRemovePhoto: () -> Void

        var body: some View {
            HStack(alignment: .center, spacing: Layout.spacing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.packagePhotoSize * scale, height: Layout.packagePhotoSize * scale)
                    .cornerRadius(Layout.cornerRadius)

                Text(Localization.photoUploaded)
                    .bodyStyle()

                Spacer()

                Menu {
                    Button(Localization.viewPhoto) {
                        onTapViewPhoto()
                    }
                    Button(Localization.replacePhoto) {
                        onTapReplacePhoto()
                    }
                    Button(role: .destructive) {
                        onTapRemovePhoto()
                    } label: {
                        Text(Localization.removePhoto)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: Layout.ellipisButtonSize * scale, height: Layout.ellipisButtonSize * scale)
                        .bodyStyle()
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(Layout.padding)
            .background(Color(.systemColor(.systemGray6)))
            .clipShape(
                .rect(
                    bottomLeadingRadius: Layout.textFieldOverlayCornerRadius,
                    bottomTrailingRadius: Layout.textFieldOverlayCornerRadius
                )
            )
        }

        enum Layout {
            static let spacing: CGFloat = 16
            static let cornerRadius: CGFloat = 4
            static let padding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            static let textFieldOverlayCornerRadius: CGFloat = 8
            static let packagePhotoSize: CGFloat = 48
            static let ellipisButtonSize: CGFloat = 24
        }

        enum Localization {
            static let photoUploaded = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.viewPhoto",
                value: "Photo uploaded",
                comment: "Button title in starting info screen."
            )
            static let viewPhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.viewPhoto",
                value: "View Photo",
                comment: "Menu button title in starting info screen."
            )
            static let replacePhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.replacePhoto",
                value: "Replace Photo",
                comment: "Menu button title in starting info screen."
            )
            static let removePhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.removePhoto",
                value: "Remove Photo",
                comment: "Menu button title in starting info screen."
            )
        }
    }
}

private extension ProductCreationAIStartingInfoView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)

        static let titleBlockBottomPadding: CGFloat = 40

        static let titleBlockSpacing: CGFloat = 16

        static let editorBlockSpacing: CGFloat = 8
        static let minimumEditorHeight: CGFloat = 70
        static let cornerRadius: CGFloat = 8
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let dividerHeight: CGFloat = 1
        static let readTextFromPhotoButtonInsets: EdgeInsets = .init(top: 11, leading: 16, bottom: 11, trailing: 16)

        enum UsePackagePhoto {
            static let padding: CGFloat = 4
            static let spacing: CGFloat = 4
            static let cameraSFSymbol = "camera"
        }
    }

    enum Localization {
        static let title = NSLocalizedString(
            "productCreationAIStartingInfoView.title",
            value: "Starting information",
            comment: "Title on the starting info screen."
        )
        static let subtitle = NSLocalizedString(
            "productCreationAIStartingInfoView.subtitle",
            value: "Tell us about your product, what it is and what makes it unique, then let the AI work its magic.",
            comment: "Subtitle on the starting info screen."
        )
        static let placeholder = NSLocalizedString(
            "productCreationAIStartingInfoView.placeholder",
            value: "For example: Black cotton t-shirt, soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product features field"
        )
        static let readTextFromPhoto = NSLocalizedString(
            "productCreationAIStartingInfoView.readTextFromPhoto",
            value: "Read text from product photo",
            comment: "Upload package photo button on the text field"
        )
        static let continueText = NSLocalizedString(
            "productCreationAIStartingInfoView.continueText",
            value: "Continue",
            comment: "Continue button on the starting info screen."
        )
    }
}

struct ProductCreationAIStartingInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCreationAIStartingInfoView(viewModel: .init(siteID: 123), onUsePackagePhoto: { _ in }, onContinueWithFeatures: { _ in })
    }
}
