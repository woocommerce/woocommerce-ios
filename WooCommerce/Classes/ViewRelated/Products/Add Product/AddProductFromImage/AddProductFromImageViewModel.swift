import Foundation
import PhotosUI
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@MainActor
final class AddProductFromImageViewModel: ObservableObject {

    // MARK: - Product Details

    @Published var name: String = ""
    @Published var features: String = ""
    @Published var sku: String = ""

    // MARK: - Product Image

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
    struct ProductImage: Transferable {
        let image: UIImage

        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                return ProductImage(image: uiImage)
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
}

// MARK: - SwiftUI Photos Picker
//
@available(iOS 16.0, *)
private extension AddProductFromImageViewModel {
    func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: ProductImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                    case .success(let image?):
                        self.imageState = .success(image.image)
                    case .success(nil):
                        self.imageState = .empty
                    case .failure(let error):
                        self.imageState = .failure(error)
                }
            }
        }
    }
}
