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
        // initializers don't call property observers,
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
    func configure(item: OrderItemViewModel) {

        productImageView.kf.setImage(with: item.imageURL, placeholder: UIImage.productPlaceholderImage)

        name = item.name
        quantity = item.quantity
        price = item.price
        sku = item.sku
    }
}
