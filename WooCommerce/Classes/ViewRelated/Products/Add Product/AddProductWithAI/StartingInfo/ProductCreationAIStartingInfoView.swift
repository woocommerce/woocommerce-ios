import SwiftUI

/// View for entering keywords or selecting package photo for creating a new product with AI.
///
struct ProductCreationAIStartingInfoView: View {
    @ObservedObject private var viewModel: ProductCreationAIStartingInfoViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var editorIsFocused: Bool

    private let onContinueWithFeatures: (String) -> Void

    init(viewModel: ProductCreationAIStartingInfoViewModel,
         onContinueWithFeatures: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onContinueWithFeatures = onContinueWithFeatures
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.parentSpacing) {
                VStack(alignment: .leading, spacing: Layout.titleBlockSpacing) {
                    // Title label.
                    Text(Localization.title)
                        .fontWeight(.bold)
                        .titleStyle()

                    // Subtitle label.
                    Text(Localization.subtitle)
                        .foregroundStyle(Color(.secondaryLabel))
                        .bodyStyle()
                }

                VStack(alignment: .leading, spacing: Layout.textFieldBlockSpacing) {
                    VStack(alignment: .leading, spacing: Layout.editorBlockSpacing) {
                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $viewModel.features)
                                    .bodyStyle()
                                    .foregroundStyle(.secondary)
                                    .padding(insets: Layout.messageContentInsets)
                                    .frame(minHeight: Layout.minimumEditorHeight, maxHeight: .infinity)
                                    .focused($editorIsFocused)

                                // Placeholder text
                                placeholderText
                            }

                            Divider()
                                .frame(height: Layout.dividerHeight)
                                .foregroundColor(Color(.separator))

                            switch viewModel.imageState {
                            case .empty:
                                readTextFromPhotoButton
                                    .padding(insets: Layout.readTextFromPhotoButtonInsets)
                            case .loading, .success:
                                PackagePhotoView(imageState: viewModel.imageState,
                                                 onTapViewPhoto: {
                                    viewModel.didTapViewPhoto()
                                },
                                                 onTapReplacePhoto: {
                                    viewModel.didTapReplacePhoto()
                                },
                                                 onTapRemovePhoto: {
                                    viewModel.didTapRemovePhoto()
                                })
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(editorIsFocused ? Color(.brand) : Color(.separator))
                        )
                    }

                    ToneOfVoiceView(viewModel: .init(siteID: viewModel.siteID))

                    if let message = viewModel.textDetectionErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
            }
            .padding(insets: Layout.insets)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // CTA to generate product details.
                generateButton
                    .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
        .sheet(isPresented: $viewModel.isShowingViewPhotoSheet, content: {
            if case let .success(image) = viewModel.imageState {
                ViewPhoto(image: image.image, isShowing: $viewModel.isShowingViewPhotoSheet)
            }
        })
        .mediaSourceActionSheet(showsActionSheet: $viewModel.isShowingMediaPickerSourceSheet, selectMedia: { source in
            Task { @MainActor in
                await viewModel.selectImage(from: source)
            }
        })
        .notice($viewModel.notice)
    }
}

private extension ProductCreationAIStartingInfoView {
    var readTextFromPhotoButton: some View {
        HStack {
            Button {
                viewModel.didTapReadTextFromPhoto()
            } label: {
                HStack(alignment: .center, spacing: Layout.UsePackagePhoto.spacing) {
                    Image(systemName: Layout.UsePackagePhoto.cameraSFSymbol)
                        .renderingMode(.template)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .bodyStyle()
                        .padding(Layout.UsePackagePhoto.padding)

                    Text(Localization.readTextFromPhoto)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
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

    var generateButton: some View {
        Button {
            // continue
            editorIsFocused = false
            viewModel.didTapContinue()
            onContinueWithFeatures(viewModel.features)
        } label: {
            Text(Localization.generateProductDetails)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.features.isEmpty)
    }
}

private extension ProductCreationAIStartingInfoView {
    struct PackagePhotoView: View {
        @ScaledMetric private var scale: CGFloat = 1.0

        let imageState: EditableImageViewState

        let onTapViewPhoto: () -> Void
        let onTapReplacePhoto: () -> Void
        let onTapRemovePhoto: () -> Void

        var body: some View {
            HStack(alignment: .center, spacing: Layout.spacing) {
                EditableImageView(imageState: imageState,
                                  emptyContent: {})
                .frame(width: Layout.packagePhotoSize * scale, height: Layout.packagePhotoSize * scale)
                .cornerRadius(Layout.cornerRadius)

                Text(Localization.photoSelected)
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
            static let photoSelected = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.photoSelected",
                value: "Photo selected",
                comment: "Text to explain that a package photo has been selected in starting info screen."
            )
            static let viewPhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.viewPhoto",
                value: "View Photo",
                comment: "Title of button which opens the selected package photo in starting info screen."
            )
            static let replacePhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.replacePhoto",
                value: "Replace Photo",
                comment: "Title of the button which opens photo selection flow to replace selected package photo in starting info screen."
            )
            static let removePhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.packagePhotoView.removePhoto",
                value: "Remove Photo",
                comment: "Title of button which removes selected package photo in starting info screen."
            )
        }
    }
}

private extension ProductCreationAIStartingInfoView {
    struct ViewPhoto: View {
        let image: UIImage
        @Binding var isShowing: Bool

        var body: some View {
            NavigationStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(Localization.done) {
                                isShowing = false
                            }
                        }
                    }
                    .navigationTitle(Localization.packagePhoto)
                    .wooNavigationBarStyle()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }

        enum Localization {
            static let packagePhoto = NSLocalizedString(
                "productCreationAIStartingInfoView.viewPhoto.packagePhoto",
                value: "Package photo",
                comment: "Title of the view package photo screen."
            )
            static let done = NSLocalizedString(
                "productCreationAIStartingInfoView.viewPhoto.done",
                value: "Done",
                comment: "Title of the button to dismiss the view package photo screen."
            )
        }
    }
}

private extension ProductCreationAIStartingInfoView {
    struct ToneOfVoiceView: View {
        @ObservedObject var viewModel: AIToneVoiceViewModel

        var body: some View {
            HStack(alignment: .center) {
                Text(Localization.title)
                    .bodyStyle()

                Spacer()

                Menu {
                    ForEach(viewModel.tones, id: \.self) { tone in
                        Button(tone.description) {
                            viewModel.onSelectTone(tone)
                        }
                    }
                } label: {
                    HStack(alignment: .center, spacing: Layout.hSpacing) {
                        Text(viewModel.selectedTone.description)
                            .foregroundStyle(Color.accentColor)
                            .bodyStyle()

                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(Color.accentColor)
                            .bodyStyle()
                    }
                }
            }
        }

        enum Layout {
            static let hSpacing: CGFloat = 4
        }

        enum Localization {
            static let title = NSLocalizedString(
                "productCreationAIStartingInfoView.toneOfVoiceView.title",
                value: "Tone of voice",
                comment: "Title of the AI tone selection button."
            )
        }
    }
}

private extension ProductCreationAIStartingInfoView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)

        static let parentSpacing: CGFloat = 24

        static let titleBlockSpacing: CGFloat = 16
        static let textFieldBlockSpacing: CGFloat = 24

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
            comment: "Subtitle on the starting info screen explaining what text to enter in the textfield."
        )
        static let placeholder = NSLocalizedString(
            "productCreationAIStartingInfoView.placeholder",
            value: "For example: Black cotton t-shirt, soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product features field"
        )
        static let readTextFromPhoto = NSLocalizedString(
            "productCreationAIStartingInfoView.readTextFromPhoto",
            value: "Read text from product photo",
            comment: "Button to upload package photo to read text from the photo"
        )
        static let generateProductDetails = NSLocalizedString(
            "productCreationAIStartingInfoView.generateProductDetails",
            value: "Generate Product Details",
            comment: "Button to generate product details in the starting info screen."
        )
    }
}

struct ProductCreationAIStartingInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCreationAIStartingInfoView(viewModel: .init(siteID: 123), onContinueWithFeatures: { _ in })
    }
}
