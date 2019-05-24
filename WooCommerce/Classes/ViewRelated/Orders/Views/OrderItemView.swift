import UIKit
import Gridicons
import Yosemite


/// Product Details: Renders a row that displays a single Product.
///
class OrderItemView: UIView {

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

    class func makeFromNib() -> OrderItemView {
        return Bundle.main.loadNibNamed("ProductDetailsTableViewCell", owner: self, options: nil)?.first as! OrderItemView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        productImageView.image = Gridicon.iconOfType(.product)
        productImageView.tintColor = StyleManager.wooGreyBorder

        nameLabel.applyBodyStyle()
        quantityLabel.applyBodyStyle()
        priceLabel.applySecondaryFootnoteStyle()
        skuLabel.applySecondaryFootnoteStyle()

        nameLabel?.text = ""
        quantityLabel?.text = ""
        priceLabel?.text = ""
        skuLabel?.text = ""
    }
}


// MARK: - Public Methods
//
extension OrderItemView {
    func configure(item: OrderItemViewModel, image: UIImage? = nil) {
        if let itemImage = image {
            productImageView.image = itemImage
        }
        name = item.name
        quantity = item.quantity
        price = item.price
        sku = item.sku
    }
}
