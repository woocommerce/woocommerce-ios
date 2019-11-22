import UIKit
import Yosemite

final class ProductImagesHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var viewModel: ProductImagesViewModel?
    private var datasource: ProductImagesCollectionViewDatasource?
    
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
        collectionView.collectionViewLayout = ProductImagesFlowLayout()
    }
}
