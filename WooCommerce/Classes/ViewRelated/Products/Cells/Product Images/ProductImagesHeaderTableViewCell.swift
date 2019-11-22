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
        
        collectionView.delegate = self
        collectionView.dataSource = datasource
        
        viewModel.registerCollectionViewCells(collectionView)
    }
    
}

extension ProductImagesHeaderTableViewCell: UICollectionViewDelegate {
    
}

/// Private Methods
private extension ProductImagesHeaderTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }
}
