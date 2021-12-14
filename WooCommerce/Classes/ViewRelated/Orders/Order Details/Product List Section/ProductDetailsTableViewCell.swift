import UIKit
import Gridicons
import Yosemite
import WordPressUI


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

    /// The label showing the SKU.
    ///
    @IBOutlet private var skuLabel: UILabel!

    /// The stack view grouping add on information.
    ///
    @IBOutlet private var viewAddOnsStackView: UIStackView!

    /// The label indicating that there are add-ons available.
    ///
    @IBOutlet private var viewAddOnsLabel: UILabel!

    /// The chevron indicator next to the viewAddOns label.
    ///
    @IBOutlet private var viewAddOnsIndicator: UIImageView!

    /// Assign this closure to be notified when the "viewAddOns" button us tapped
    ///
    var onViewAddOnsTouchUp: (() -> Void)?

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
        configureSKULabel()
        configureSubtitleLabel()
        configureSelectionStyle()
        configureAddOnViews()
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
        productImageView.image = UIImage.productPlaceholderImage
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
        subtitleLabel?.numberOfLines = 0
        subtitleLabel?.text = ""
    }

    func configureSKULabel() {
        skuLabel.applySecondaryFootnoteStyle()
        skuLabel?.text = ""
    }

    func configureAddOnViews() {
        viewAddOnsStackView.layoutMargins = .init(top: 4, left: 0, bottom: 4, right: 0) // Increase touch area
        viewAddOnsStackView.isLayoutMarginsRelativeArrangement = true
        viewAddOnsStackView.spacing = 2

        viewAddOnsLabel.applySubheadlineStyle()
        viewAddOnsLabel.text = Localization.viewAddOns

        viewAddOnsIndicator.image = .chevronImage
        viewAddOnsIndicator.tintColor = .systemGray

        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.on { [weak self] _ in
            self?.onViewAddOnsTouchUp?()
        }
        viewAddOnsStackView.addGestureRecognizer(tapRecognizer)
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
                                                       placeholder: UIImage.productPlaceholderImage.imageWithTintColor(UIColor.listIcon),
                                                       progressBlock: nil,
                                                       completion: nil)

        nameLabel.text = item.name
        priceLabel.text = item.total
        subtitleLabel.text = item.subtitle
        skuLabel.text = item.sku
        viewAddOnsStackView.isHidden = !item.hasAddOns
    }
}

// MARK: Localization
private extension ProductDetailsTableViewCell {
    enum Localization {
        static let viewAddOns = NSLocalizedString("View Add-Ons", comment: "Title of the button on the order detail item to navigate to add-ons")
    }
}

extension ProductDetailsTableViewCell {
    func configureForInventoryScannerResult(product: ProductFormDataModel, updatedQuantity: Decimal?, imageService: ImageService) {
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
