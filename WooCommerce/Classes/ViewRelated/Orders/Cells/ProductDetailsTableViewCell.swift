import UIKit
import Gridicons
import Yosemite


/// Product Details: Renders a row that displays a single Product.
///
class ProductDetailsTableViewCell: UITableViewCell {

    /// Label: Image
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

    /// Label: Tax
    ///
    @IBOutlet private var taxLabel: UILabel!

    /// Label: SKU
    ///
    @IBOutlet private var skuLabel: UILabel!


    /// Product Name
    ///
    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }

    /// Number of Items
    ///
    var quantity: String? {
        get {
            return quantityLabel.text
        }
        set {
            quantityLabel.text = newValue
        }
    }

    /// Item's Price
    ///
    var price: String? {
        get {
            return priceLabel.text
        }
        set {
            priceLabel.text = newValue
        }
    }

    /// Item's Tax
    ///
    var tax: String? {
        get {
            return taxLabel.text
        }
        set {
            taxLabel.text = newValue
        }
    }

    /// Item's SKU
    ///
    var sku: String? {
        get {
            return skuLabel.text
        }
        set {
            skuLabel.text = newValue
        }
    }



    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        productImageView.image = Gridicon.iconOfType(.product)
        productImageView.tintColor = StyleManager.wooGreyBorder
        nameLabel.applyBodyStyle()
        quantityLabel.applyBodyStyle()
        priceLabel.applyFootnoteStyle()
        taxLabel.applyFootnoteStyle()
        skuLabel.applyFootnoteStyle()
    }
}


// MARK: - Public Methods
//
extension ProductDetailsTableViewCell {
    func configure(item: OrderItemViewModel, with details: OrderDetailsViewModel) {
        nameLabel.text = item.name
        quantityLabel.text = item.quantity
        priceLabel.text = item.price
        taxLabel.text = item.tax
        skuLabel.text = item.sku
    }
}
