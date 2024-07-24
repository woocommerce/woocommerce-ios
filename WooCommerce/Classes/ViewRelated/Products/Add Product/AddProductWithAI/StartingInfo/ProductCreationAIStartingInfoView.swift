import SwiftUI

/// View for entering keywords or selecting package photo for creating a new product with AI.
///
struct ProductCreationAIStartingInfoView: View {
    @ObservedObject private var viewModel: ProductCreationAIStartingInfoViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var editorIsFocused: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isCompact: Bool {
        verticalSizeClass == .compact
    }
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
                            VStack(spacing: Layout.editorBlockSpacing) {
                                textField(with: proxy)

                                if viewModel.featureFlagService.isFeatureFlagEnabled(.productCreationAIv2M3) &&
                                    (editorIsFocused || viewModel.features.isNotEmpty) {
                                    ProductCreationAIPromptProgressBar(text: $viewModel.features)
                                }

                                photoSection
                            }
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
            .scrollDismissesKeyboard(.immediately)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                generateButton(isPrimary: false)
                    .renderedIf(isCompact)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()
                // CTA to generate product details.
                generateButton(isPrimary: true)
                    .padding()
            }
            .background(Color(uiColor: .systemBackground))
            .renderedIf(!isCompact)
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
    func textField(with proxy: ScrollViewProxy) -> some View {
        TextField(Localization.placeholder, text: $viewModel.features, axis: .vertical)
            .id(Constant.textFieldID)
            .bodyStyle()
            .foregroundStyle(.secondary)
            .lineLimit(Constant.textFieldMinLineLength...)
            .padding(insets: Layout.messageContentInsets)
            .focused($editorIsFocused)
            // Scrolls to the "TextField" view with a smooth animation while typing.
            .onChange(of: viewModel.features) { _ in
                scrollToTextField(using: proxy)
            }
            // Scrolls to the "TextField" view with a smooth animation when the editor is focused in a small screen.
            .onChange(of: editorIsFocused) { isFocused in
                if isFocused {
                    scrollToTextField(using: proxy)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(editorIsFocused ? Color(.brand) : Color(.separator))
            )
    }

    @ViewBuilder
    var photoSection: some View {
        switch viewModel.imageState {
        case .empty:
            readTextFromPhotoButton
                .mediaSourceActionSheet(showsActionSheet: $viewModel.isShowingMediaPickerSourceSheet, selectMedia: { source in
                    Task { @MainActor in
                        await viewModel.selectImage(from: source)
                    }
                })
        case .loading, .success:
            PackagePhotoView(title: Localization.photoSelected,
                             subTitle: Localization.textAddedToInfo,
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
            .mediaSourceActionSheet(showsActionSheet: $viewModel.isShowingMediaPickerSourceSheet, selectMedia: { source in
                Task { @MainActor in
                    await viewModel.selectImage(from: source)
                }
            })
        }
    }

    var readTextFromPhotoButton: some View {
        Button {
            viewModel.didTapReadTextFromPhoto()
        } label: {
            AdaptiveStack(horizontalAlignment: .leading,
                          verticalAlignment: .top,
                          spacing: Layout.UsePackagePhoto.spacing) {
                VStack {
                    Image(systemName: Layout.UsePackagePhoto.cameraSFSymbol)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: Layout.UsePackagePhoto.imageSize * scale,
                               height: Layout.UsePackagePhoto.imageSize * scale)
                }
                .frame(width: Layout.UsePackagePhoto.imageHolderViewSize * scale,
                       height: Layout.UsePackagePhoto.imageHolderViewSize * scale)
                .background(Color(light: Color(.systemColor(.systemGray5)),
                                  dark: Color(.systemColor(.systemGray4))))
                .clipShape(RoundedRectangle(cornerRadius: Layout.UsePackagePhoto.imageHolderViewCornerRadius))

                VStack(alignment: .leading) {
                    Text(Localization.scanPhotoTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .bodyStyle()
                    Text(Localization.scanPhotoDescription)
                        .footnoteStyle()
                }
                .multilineTextAlignment(.leading)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(Layout.insets)
            .background(Color(light: Color(.systemColor(.systemGray6)),
                              dark: Color(.systemColor(.systemGray5))))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        }
    }

    func generateButton(isPrimary: Bool) -> some View {
        Button {
            // continue
            editorIsFocused = false
            onContinueWithFeatures(viewModel.features)
        } label: {
            Text(Localization.generateProductDetails)
        }
        .if(isPrimary, transform: { button in
            button.buttonStyle(PrimaryButtonStyle())
        })
        .disabled(viewModel.features.isEmpty)
    }


    private func scrollToTextField(using proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(Constant.textFieldID, anchor: .top)
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
        static let cornerRadius: CGFloat = 8
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let dividerHeight: CGFloat = 1

        enum UsePackagePhoto {
            static let imageSize: CGFloat = 24
            static let imageHolderViewSize: CGFloat = 48
            static let imageHolderViewCornerRadius: CGFloat = 4
            static let spacing: CGFloat = 16
            static let cameraSFSymbol = "camera"
        }
    }

    enum Constant {
        static let textFieldID = "TextField"
        static let textFieldMinLineLength = 3
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
        static let scanPhotoTitle = NSLocalizedString(
            "productCreationAIStartingInfoView.scanPhotoTitle",
            value: "Scan a product photo",
            comment: "Title of button to upload package photo to read text from the photo"
        )
        static let scanPhotoDescription = NSLocalizedString(
            "productCreationAIStartingInfoView.scanPhotoDescription",
            value: "Add a text scanned from a photo",
            comment: "Description of button to upload package photo to read text from the photo"
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
        static let textAddedToInfo = NSLocalizedString(
            "productCreationAIStartingInfoView.textAddedToInfo",
            value: "Photo text added to starting info",
            comment: "Text to explain that text scanned from a package photo has been added to the starting info screen."
        )
    }
}

struct ProductCreationAIStartingInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCreationAIStartingInfoView(viewModel: .init(siteID: 123), onContinueWithFeatures: { _ in })
    }
}
