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
    init(completion: @escaping (AddProductFromImageData) -> Void) {
        super.init(rootView: AddProductFromImageView(completion: completion))
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
                Text("Upload a photo of the packaging to select text for name and features")
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
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
            .frame(height: 500)
    }
}

@available(iOS 16.0, *)
struct EditableProductImageView: View {
    @ObservedObject var viewModel: AddProductFromImageViewModel

    var body: some View {
        ProductImageView(imageState: viewModel.imageState)
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $viewModel.imageSelection,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.init(uiColor: .accent))
                }
                             .buttonStyle(.borderless)
            }
    }
}

@available(iOS 16.0, *)
struct AddProductFromImageView: View {
    private let completion: (AddProductFromImageData) -> Void
    @StateObject private var viewModel = AddProductFromImageViewModel()

    init(completion: @escaping (AddProductFromImageData) -> Void) {
        self.completion = completion
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
                          prompt: Text("Product Name"))
                TextField("Features",
                          text: $viewModel.features,
                          axis: .vertical)
                .lineLimit(2...5)
            }
            Section {
                TextField("Barcode/SKU",
                          text: $viewModel.sku,
                          prompt: Text("Barcode/SKU"))
            }
        }
        .navigationTitle("Add product")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Continue") {
                    // TODO: pass image
                    completion(.init(name: viewModel.name, description: viewModel.features, sku: viewModel.sku, image: nil))
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
    }
}

struct AddProductFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            AddProductFromImageView(completion: { _ in })
        }
    }
}
