import UIKit
import Gridicons
import Yosemite


/// Product Details: Renders a row that displays a single Product.
///
final class ProductDetailsTableViewCell: UITableViewCell {

    /// ImageView
    ///
    @IBOutlet private var productImageView: UIImageView!

    /// Label: Name
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// Label: Quantity
    ///
    @IBOutlet private var priceLabel: UILabel!

    /// Label: Price
    ///
    @IBOutlet private var subtitleLabel: UILabel!

    /// Label: SKU
    ///
    @IBOutlet private var skuLabel: UILabel!

    // MARK: - Overridden Methods

    required init?(coder aDecoder: NSCoder) {
        // Initializers don't call property observers,
        // so don't set the default for mode here.
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureProductImageView()
        configureNameLabel()
        configureQuantityLabel()
        configureSKULabel()
        configurePriceLabel()
        configureSelectionStyle()
    }
}


private extension ProductDetailsTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    func configureProductImageView() {
        productImageView.image = .productPlaceholderImage
        productImageView.tintColor = .listSmallIcon
        productImageView.contentMode = .scaleAspectFill
        productImageView.clipsToBounds = true
    }

    func configureNameLabel() {
        nameLabel.applyBodyStyle()
        nameLabel?.text = ""
    }

    func configureQuantityLabel() {
        priceLabel.applyBodyStyle()
        priceLabel?.text = ""
    }

    func configurePriceLabel() {
        subtitleLabel.applySecondaryFootnoteStyle()
        subtitleLabel?.text = ""
    }

    func configureSKULabel() {
        skuLabel.applySecondaryFootnoteStyle()
        skuLabel?.text = ""
    }

    func configureSelectionStyle() {
        selectionStyle = .none
    }
}


// MARK: - Public Methods
//
extension ProductDetailsTableViewCell {
    /// Configure a product detail cell
    ///
    func configure(item: ProductDetailsCellViewModel, imageService: ImageService) {
        imageService.downloadAndCacheImageForImageView(productImageView,
                                                       with: item.imageURL?.absoluteString,
                                                       placeholder: .productPlaceholderImage,
                                                       progressBlock: nil,
                                                       completion: nil)

        nameLabel.text = item.name
        priceLabel.text = item.quantity
        subtitleLabel.text = item.price
        skuLabel.text = item.sku
    }
}
