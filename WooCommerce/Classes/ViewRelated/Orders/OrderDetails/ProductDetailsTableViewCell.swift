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
    func configure(item: OrderItem, with details: OrderDetailsViewModel) {
        nameLabel.text = item.name
        quantityLabel.text = "\(item.quantity)"

        let priceText = item.quantity > 1 ? "\(item.total) (\(details.currencySymbol)\(item.subtotal) × \(item.quantity))" : "\(item.total)"
        priceLabel.text = "\(details.currencySymbol)\(priceText)"

        let taxString = NSLocalizedString("Tax:", comment: "Tax label for total taxes line")
        let taxText = item.totalTax.isEmpty ? nil : "\(taxString) \(details.currencySymbol)\(item.totalTax)"
        taxLabel.text = taxText

        let skuString = NSLocalizedString("SKU:", comment: "SKU label")
        let skuText = item.sku.isEmpty ? nil : "\(skuString) \(item.sku)"
        skuLabel.text = skuText
    }
}
