import UIKit
import Gridicons
import Yosemite


/// Product Details: Renders a row that displays a single Product.
///
final class ProductDetailsTableViewCell: UITableViewCell {

    /// Shows the product's image.
    ///
    @IBOutlet private var productImageView: UIImageView!

    /// The label for the product's name.
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// The label for the subtotal (quantity x item price).
    ///
    @IBOutlet private var priceLabel: UILabel!

    /// The label showing the pattern "{qty} x {item_price}".
    ///
    @IBOutlet private var subtitleLabel: UILabel!

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
        configurePriceLabel()
        configureSubtitleLabel()
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

    func configurePriceLabel() {
        priceLabel.applyBodyStyle()
        priceLabel?.text = ""
    }

    func configureSubtitleLabel() {
        subtitleLabel.applySecondaryFootnoteStyle()
        subtitleLabel?.text = ""
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
        priceLabel.text = item.total
        subtitleLabel.text = item.subtitle
    }
}

extension ProductDetailsTableViewCell {
    func configureForInventoryScannerResult(product: Product, updatedQuantity: Int?, imageService: ImageService) {
        imageService.downloadAndCacheImageForImageView(productImageView,
                                                       with: product.images.first?.src,
                                                       placeholder: .productPlaceholderImage,
                                                       progressBlock: nil,
                                                       completion: nil)

        nameLabel.text = product.name
        // TODO-jc: update
//        skuLabel.text = product.sku

        guard product.manageStock else {
            priceLabel.text = NSLocalizedString("⚠️ Stock management is disabled", comment: "")
            subtitleLabel.text = ""
            return
        }

        priceLabel.text = ""

        let originalQuantity = product.stockQuantity ?? 0
        if let updatedQuantity = updatedQuantity, updatedQuantity != originalQuantity {
            subtitleLabel.text = "\(originalQuantity) → \(updatedQuantity)"
            subtitleLabel.textColor = .warning
        } else {
            subtitleLabel.text = "\(originalQuantity)"
            subtitleLabel.textColor = .text
        }
    }
}
