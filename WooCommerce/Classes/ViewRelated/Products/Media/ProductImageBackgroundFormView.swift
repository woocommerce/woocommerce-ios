import SwiftUI
import struct Networking.SceneOptions

/// Hosting controller for `ProductImageBackgroundFormView`.
///
final class ProductImageBackgroundFormHostingController: UIHostingController<ProductImageBackgroundFormView> {
    init(viewModel: ProductImageBackgroundFormViewModel, imageAdded: @escaping (UIImage) -> Void) {
        super.init(rootView: ProductImageBackgroundFormView(viewModel: viewModel,
                                                            imageAdded: imageAdded))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ProductImageBackgroundFormView: View {
    @ObservedObject private var viewModel: ProductImageBackgroundFormViewModel
    private let imageAdded: (UIImage) -> Void

    init(viewModel: ProductImageBackgroundFormViewModel, imageAdded: @escaping (UIImage) -> Void) {
        self.viewModel = viewModel
        self.imageAdded = imageAdded
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("I want to see my product")
                        .headlineStyle()
                    SegmentedView(selection: $viewModel.prepositionIndex, views: viewModel.prepositionOptions.map { Text($0.rawValue) })
                    TextEditor(text: $viewModel.prompt)
                        .bodyStyle()
                        .foregroundColor(.secondary)
                        .frame(minHeight: Layout.minimuEditorSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Scale")
                        .subheadlineStyle()
                    Slider(value: $viewModel.scale, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resolution")
                        .subheadlineStyle()
                    SegmentedView(selection: $viewModel.resolutionIndex, views: viewModel.resolutionOptions.map { Text($0.description) })
                }

                HStack {
                    ForEach(viewModel.modifiers, id: \.self) {
                        BadgeView(text: $0)
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Time of day")
                        Picker("Time of day", selection: $viewModel.timeOfDay) {
                            ForEach(viewModel.timeOfDayOptions, id: \.self) {
                                Text($0?.rawValue ?? "None")
                            }
                        }
                    }

                    HStack {
                        Text("Perspective")
                        Picker("Perspective", selection: $viewModel.perspective) {
                            ForEach(viewModel.perspectiveOptions, id: \.self) {
                                Text($0?.rawValue ?? "None")
                            }
                        }
                    }

                    HStack {
                        Text("Filters")
                        Picker("Filters", selection: $viewModel.filters) {
                            ForEach(viewModel.filtersOptions, id: \.self) {
                                Text($0?.rawValue ?? "None")
                            }
                        }
                    }

                    HStack {
                        Text("Placement")
                        Picker("Placement", selection: $viewModel.placement) {
                            ForEach(viewModel.placementOptions, id: \.self) {
                                Text($0?.rawValue ?? "None")
                            }
                        }
                    }

                    HStack {
                        Text("Vibe")
                        Picker("Vibe", selection: $viewModel.vibe) {
                            ForEach(viewModel.vibeOptions, id: \.self) {
                                Text($0?.rawValue ?? "None")
                            }
                        }
                    }
                }

                HStack {
                    Button(viewModel.generatedImage == nil ? "Generate": "Regenerate") {
                        Task { @MainActor in
                            await viewModel.replaceBackground()
                        }
                    }
                    .disabled(viewModel.prompt.isEmpty)
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isGenerationInProgress))

                    if let generatedImage = viewModel.generatedImage {
                        Button("Use for product") {
                            imageAdded(generatedImage)
                        }
                    }
                }


                if let generatedImage = viewModel.generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                }
            }.padding()
        }
    }
}

// MARK: Constants
private extension ProductImageBackgroundFormView {
    enum Layout {
        static let minimuEditorSize: CGFloat = 60
        static let cornerRadius: CGFloat = 8
    }
}

private extension SceneOptions.Resolution {
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .high:
            return "High"
        }
    }
}

#if DEBUG

import Photos

struct ProductImageBackgroundFormView_Previews: PreviewProvider {
    static var previews: some View {
        ProductImageBackgroundFormView(viewModel: .init(prompt: "",
                                                        productImage: .init(imageID: 1, dateCreated: .init(), dateModified: nil, src: "", name: nil, alt: nil),
                                                        productUIImageLoader: DefaultProductUIImageLoader(productImageActionHandler: .init(siteID: 0, productID: .product(id: 0), imageStatuses: []),
                                                                                                          phAssetImageLoaderProvider: { PHImageManager.default() })),
                                       imageAdded: { _ in })
    }
}

#endif
