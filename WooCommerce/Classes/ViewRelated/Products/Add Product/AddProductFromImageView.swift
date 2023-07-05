import PhotosUI
import SwiftUI
import Yosemite

struct AddProductFromImageData {
    let name: String
    let description: String
    let sku: String?
    let image: UIImage?
}

@available(iOS 16.0, *)
final class AddProductFromImageHostingController: UIHostingController<AddProductFromImageView> {
    init(siteID: Int64,
         addImage: @escaping (MediaPickingSource) async -> UIImage?,
         completion: @escaping (AddProductFromImageData) -> Void) {
        super.init(rootView: AddProductFromImageView(siteID: siteID, addImage: addImage, completion: completion))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 16.0, *)
struct ProductLiveTextImage: View {
    let imageState: AddProductFromImageViewModel.ImageState

    var body: some View {
        switch imageState {
        case .success(let image):
            ZoomableScrollView {
                LiveTextInteractionView(image: image)
            }
        case .loading:
            ProgressView()
        case .empty:
            VStack(spacing: 16) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                Label {
                    Text("Take a packaing photo to create product details with AI")
                } icon: {
                    Image(uiImage: .sparklesImage)
                }
                    .foregroundColor(.init(uiColor: .accent))
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}

@available(iOS 16.0, *)
struct ProductImageView: View {
    let imageState: AddProductFromImageViewModel.ImageState

    var body: some View {
        ProductLiveTextImage(imageState: imageState)
            .scaledToFit()
            .frame(maxHeight: 400)
    }
}

@available(iOS 16.0, *)
struct EditableProductImageView: View {
    @ObservedObject var viewModel: AddProductFromImageViewModel
    @State private var isShowingActionSheet: Bool = false

    var body: some View {
        ProductImageView(imageState: viewModel.imageState)
            .overlay(alignment: .topTrailing) {
                Button {
                    isShowingActionSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.init(uiColor: .accent))
                }
                .actionSheet(isPresented: $isShowingActionSheet) {
                    ActionSheet(title: Text("SwiftUI ActionSheet"),
                                message: nil,
                                buttons: [
                                    //                                    (UIImagePickerController.isSourceTypeAvailable(.camera) ?
                                    //                                        .default(Text(NSLocalizedString("Take a photo",
                                    //                                                                        comment: "Menu option for taking an image or video with the device's camera."))) {
                                    //                                            Task { @MainActor in
                                    //                                                await viewModel.addImage()
                                    //                                            }
                                    //                                        }) : nil),
                                    .default(Text(NSLocalizedString("Choose from device",
                                                                    comment: "Menu option for selecting media from the device's photo library."))) {
                                                                        Task { @MainActor in
                                                                            await viewModel.addImage(from: .photoLibrary)
                                                                        }
                                                                    },
                                    .cancel()
                                ].compactMap { $0 })
                }
            }
    }
}

@available(iOS 16.0, *)
struct AddProductFromImageView: View {
    private let completion: (AddProductFromImageData) -> Void
    @StateObject private var viewModel: AddProductFromImageViewModel

    init(siteID: Int64,
         addImage: @escaping (MediaPickingSource) async -> UIImage?,
         completion: @escaping (AddProductFromImageData) -> Void) {
        self._viewModel = StateObject(wrappedValue: AddProductFromImageViewModel(siteID: siteID, onAddImage: addImage))
        self.completion = completion
        self._viewModel = .init(wrappedValue: AddProductFromImageViewModel(siteID: siteID, onAddImage: addImage))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    EditableProductImageView(viewModel: viewModel)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .padding([.top], 10)

            Section {
                TextField("Name",
                          text: $viewModel.name,
                          axis: .vertical)
                .fixedSize(horizontal: false, vertical: true)

                TextField("Description",
                          text: $viewModel.description,
                          axis: .vertical)
                .lineLimit(2...5)
                .fixedSize(horizontal: false, vertical: true)
            }
            .redacted(reason: viewModel.isGeneratingDetails ? .placeholder : [])
            .shimmering(active: viewModel.isGeneratingDetails)

            Text("Generating details with the scanned texts:")
                .renderedIf(viewModel.isGeneratingDetails)
            List(viewModel.scannedTexts, id: \.self, selection: $viewModel.selectedScannedTexts) { scannedText in
//                Text(scannedText)
                Button(action: {
                    if viewModel.selectedScannedTexts.contains(scannedText) {
                        viewModel.selectedScannedTexts.remove(scannedText)
                    } else {
                        viewModel.selectedScannedTexts.insert(scannedText)
                    }
                }) {
                    HStack {
                        Text(scannedText)
                        Spacer()
                        Image(systemName: viewModel.selectedScannedTexts.contains(scannedText) ? "checkmark.circle.fill" : "circle")
                    }
                }
            }
            .environment(\.editMode, .constant(EditMode.active))
            .renderedIf(viewModel.scannedTexts.isNotEmpty)

            // TODO-JC: language picker
//            Section {
//                Picker(selection: $selectedSiteIDSourceType, label: EmptyView()) {
//                    ForEach(SiteIDSourceType.allCases, id: \.self) { option in
//                        Text(option.title)
//                    }
//                }
//                .pickerStyle(.segmented)
//            }
        }
        .navigationTitle("Add product")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Continue") {
                    // TODO-JC: pass image
                    completion(.init(name: viewModel.name, description: viewModel.description, sku: viewModel.sku, image: nil))
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
    }
}

struct AddProductFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            AddProductFromImageView(siteID: 134, addImage: { _ in nil }, completion: { _ in })
        }
    }
}
