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
        ScrollViewReader { proxy in
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
                                        .id("TextEditor")
                                        .bodyStyle()
                                        .foregroundStyle(.secondary)
                                        .padding(insets: Layout.messageContentInsets)
                                        .frame(minHeight: Layout.minimumEditorHeight, maxHeight: .infinity)
                                        .focused($editorIsFocused)
                                    // Scrolls to the "TextEditor" view with a smooth animation while typing.
                                        .onChange(of: viewModel.features) { _ in
                                            withAnimation {
                                                proxy.scrollTo("TextEditor", anchor: .top)
                                            }
                                        }
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
                                        .mediaSourceActionSheet(showsActionSheet: $viewModel.isShowingMediaPickerSourceSheet, selectMedia: { source in
                                            Task { @MainActor in
                                                await viewModel.selectImage(from: source)
                                            }
                                        })
                                case .loading, .success:
                                    PackagePhotoView(title: Localization.photoSelected,
                                                     imageState: viewModel.imageState,
                                                     onTapViewPhoto: {
                                        viewModel.didTapViewPhoto()
                                    },
                                                     onTapReplacePhoto: {
                                        viewModel.didTapReplacePhoto()
                                    },
                                                     onTapRemovePhoto: {
                                        viewModel.didTapRemovePhoto()
                                    })
                                    .clipShape(
                                        .rect(
                                            bottomLeadingRadius: Layout.cornerRadius,
                                            bottomTrailingRadius: Layout.cornerRadius
                                        )
                                    )
                                    .mediaSourceActionSheet(showsActionSheet: $viewModel.isShowingMediaPickerSourceSheet, selectMedia: { source in
                                        Task { @MainActor in
                                            await viewModel.selectImage(from: source)
                                        }
                                    })
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(editorIsFocused ? Color(.brand) : Color(.separator))
                            )
                        }
                        if viewModel.featureFlagService.isFeatureFlagEnabled(.productCreationAIv2M3) && (editorIsFocused || viewModel.features.isNotEmpty) {
                            ProductCreationAIPromptProgressBar(text: $viewModel.features)
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
                .onTapGesture {
                    // Dismiss the keyboard when the view is tapped.
                    editorIsFocused = false
                }
                .padding(insets: Layout.insets)
            }
            // Scrolls to the "TextEditor" view with a smooth animation when the editor is focused in a small screen.
            .onChange(of: editorIsFocused) { isFocused in
                if isFocused {
                    withAnimation {
                        proxy.scrollTo("TextEditor", anchor: .top)
                    }
                }
            }
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
                ViewPackagePhoto(image: image.image, isShowing: $viewModel.isShowingViewPhotoSheet)
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
        static let photoSelected = NSLocalizedString(
            "productCreationAIStartingInfoView.photoSelected",
            value: "Photo selected",
            comment: "Text to explain that a package photo has been selected in starting info screen."
        )
    }
}

struct ProductCreationAIStartingInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCreationAIStartingInfoView(viewModel: .init(siteID: 123), onContinueWithFeatures: { _ in })
    }
}
