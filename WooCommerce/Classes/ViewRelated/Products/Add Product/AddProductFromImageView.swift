import SwiftUI
import PhotosUI
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
            LiveTextInteractionView(image: image)
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
@MainActor
final class AddProductFromImageViewModel: ObservableObject {

    // MARK: - Profile Details

    @Published var name: String = ""
    @Published var features: String = ""
    @Published var sku: String = ""

    // MARK: - Profile Image

    enum ImageState {
        case empty
        case loading(Progress)
        case success(UIImage)
        case failure(Error)
    }

    enum TransferError: Error {
        case importFailed
    }

    @available(iOS 16.0, *)
    struct ProfileImage: Transferable {
        let image: UIImage

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return ProfileImage(image: uiImage)
            }
        }
    }

    @Published private(set) var imageState: ImageState = .empty

    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }

    // MARK: - Private Methods

    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage?):
                    self.imageState = .success(profileImage.image)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
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
