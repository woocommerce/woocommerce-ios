import UIKit
import Gridicons
import Yosemite


/// Product Details: Renders a row that displays a single Product.
///
class ProductDetailsTableViewCell: UITableViewCell {

    /// ImageView
    ///
    @IBOutlet private var productImageView: UIImageView!

    /// Label: Name
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// Label: Quantity
    ///
    @IBOutlet private var quantityLabel: UILabel!

    /// Label: Price
    ///
    @IBOutlet private var priceLabel: UILabel!

    /// Label: SKU
    ///
    @IBOutlet private var skuLabel: UILabel!

    /// Product Name
    ///
    var name: String? {
        get {
            return nameLabel?.text
        }
        set {
            nameLabel?.text = newValue
        }
    }

    /// Number of Items
    ///
    var quantity: String? {
        get {
            return quantityLabel?.text
        }
        set {
            quantityLabel?.text = newValue
        }
    }

    /// Item's Price
    ///
    var price: String? {
        get {
            return priceLabel?.text
        }
        set {
            priceLabel?.text = newValue
        }
    }

    /// Item's SKU
    ///
    var sku: String? {
        get {
            return skuLabel?.text
        }
        set {
            skuLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    required init?(coder aDecoder: NSCoder) {
        // Initializers don't call property observers,
        // so don't set the default for mode here.
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> ProductDetailsTableViewCell {
        return Bundle.main.loadNibNamed("ProductDetailsTableViewCell", owner: self, options: nil)?.first as! ProductDetailsTableViewCell
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
        quantityLabel.applyBodyStyle()
        quantityLabel?.text = ""
    }

    func configurePriceLabel() {
        priceLabel.applySecondaryFootnoteStyle()
        priceLabel?.text = ""
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

        name = item.name
        quantity = item.quantity
        price = item.price
        sku = item.sku
    }
}

extension ProductDetailsTableViewCell {
    func configureForInventoryScannerResult(product: Product, updatedQuantity: Int?, imageService: ImageService) {
        imageService.downloadAndCacheImageForImageView(productImageView,
                                                       with: product.images.first?.src,
                                                       placeholder: .productPlaceholderImage,
                                                       progressBlock: nil,
                                                       completion: nil)

        name = product.name
        sku = product.sku

        guard product.manageStock else {
            priceLabel.text = NSLocalizedString("⚠️ Stock management is disabled", comment: "")
            quantity = ""
            return
        }

        priceLabel.text = ""

        let originalQuantity = product.stockQuantity ?? 0
        if let updatedQuantity = updatedQuantity {
            quantity = "\(originalQuantity) → \(updatedQuantity)"
        } else {
            quantity = "\(originalQuantity)"
        }
    }
}
