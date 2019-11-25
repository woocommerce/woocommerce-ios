import UIKit
import Yosemite

final class ProductImagesHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!

    /// View Model
    ///
    private var viewModel: ProductImagesViewModel?

    /// Collection View Datasource
    ///
    private var datasource: ProductImagesCollectionViewDatasource?

    /// Closure to be executed when a image cell is tapped
    ///
    var onImageSelected: ((ProductImage?, IndexPath?) -> Void)?

    /// Closure to be executed when add image cell is tapped
    ///
    var onAddImage: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()


        configureBackground()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configure(with product: Product) {
        let viewModel = ProductImagesViewModel(product: product)
        self.viewModel = viewModel
        datasource = ProductImagesCollectionViewDatasource(viewModel: viewModel)

        configureCollectionView()

        viewModel.registerCollectionViewCells(collectionView)
    }

}

extension ProductImagesHeaderTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel?.items[indexPath.item] {
        case .image:
            onImageSelected?(viewModel?.product.images[indexPath.item], indexPath)
            break
        case .addImage:
            onAddImage?()
            break
        default:
            break
        }
    }
}

extension ProductImagesHeaderTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

//        if viewModel?.items[indexPath.item] == .image{
//            let cell = collectionView.cellForItem(at: indexPath) as? ProductImageCollectionViewCell
//            if let imageSize = cell?.imageView.image?.size{
//                return CGSize(width: (128 / imageSize.height) * imageSize.width, height: 128.0)
//            }
//        }

        return ProductImagesViewModel.defaultCollectionViewCellSize
    }
}

/// Private Methods
private extension ProductImagesHeaderTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = datasource
        collectionView.backgroundColor = StyleManager.wooWhite
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.collectionViewLayout = ProductImagesFlowLayout(itemSize: ProductImagesViewModel.defaultCollectionViewCellSize)
    }
}
