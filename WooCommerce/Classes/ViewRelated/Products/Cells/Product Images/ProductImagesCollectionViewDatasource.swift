import UIKit

final class ProductImagesCollectionViewDatasource: NSObject {
    private let viewModel: ProductImagesViewModel
    
    init(viewModel: ProductImagesViewModel) {
        self.viewModel = viewModel
        super.init()
    }
}

extension ProductImagesCollectionViewDatasource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = viewModel.items[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseIdentifier, for: indexPath)
        configure(cell, for: item, at: indexPath)
        return cell
    }
    
    
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductImagesCollectionViewDatasource {
    func configure(_ cell: UICollectionViewCell, for item: ProductImagesItem, at indexPath: IndexPath) {
        switch cell {
        case let cell as ProductImageCollectionViewCell where item == .image:
            configureImageCell(cell: cell, at: indexPath)
        case let cell as AddProductImageCollectionViewCell where item == .addImage:
            configureAddImageCell(cell: cell, at: indexPath)
        default:
            fatalError("Unidentified product image item type")
        }
    }
    
    /// Cell configuration
    ///
    func configureImageCell(cell: ProductImageCollectionViewCell, at: IndexPath) {
        
    }
    
    func configureAddImageCell(cell: AddProductImageCollectionViewCell, at: IndexPath) {
        
    }
}

enum ProductImagesItem {
    case image
    case addImage

    var reuseIdentifier: String {
        switch self {
        case .image:
            return ProductImageCollectionViewCell.reuseIdentifier
        case .addImage:
            return ProductImageCollectionViewCell.reuseIdentifier
        }
    }
    
}
