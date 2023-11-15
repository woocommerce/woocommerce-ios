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

    /// The stack view to show optional product add-ons.
    ///
    @IBOutlet private weak var addOnsStackView: UIStackView!

    /// The stack view grouping add on information.
    ///
    @IBOutlet private var viewAddOnsStackView: UIStackView!

    /// The label indicating that there are add-ons available.
    ///
    @IBOutlet private var viewAddOnsLabel: UILabel!

    /// The chevron indicator next to the viewAddOns label.
    ///
    @IBOutlet private var viewAddOnsIndicator: UIImageView!

    /// The leading constraint for the productImageView.
    ///
    @IBOutlet var productImageLeadingConstraint: NSLayoutConstraint!

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
        configureAttributesStackView()
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

    func configureAttributesStackView() {
        addOnsStackView.spacing = 6
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

    /// Adds padding between the leading margin and the product image if the product is a child product.
    ///
    func configureChildProductPadding(isChildProduct: Bool) {
        if isChildProduct {
            productImageLeadingConstraint.constant = Constants.childProductLeadingPadding
        } else {
            productImageLeadingConstraint.constant = 0
        }
    }

    func updateAddOnsStackView(viewModel: ProductDetailsCellViewModel.AddOnsViewModel) {
        addOnsStackView.isHidden = viewModel.addOns.isEmpty
        let subviews = viewModel.addOns.map { attribute in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 0

            let keyString = NSAttributedString(string: "\(attribute.key): ", attributes: [
                .font: UIFont.footnote,
                .foregroundColor: UIColor.textSubtle,
                .paragraphStyle: paragraphStyle
            ])
            let valueString = NSAttributedString(string: attribute.value, attributes: [
                .font: UIFont.footnote.bold,
                .foregroundColor: UIColor.textSubtle,
                .paragraphStyle: paragraphStyle
            ])
            let attributedString = NSMutableAttributedString(attributedString: keyString)
            attributedString.append(valueString)
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.attributedText = attributedString
            label.numberOfLines = 0
            return label
        }
        addOnsStackView.removeAllSubviews()
        addOnsStackView.addArrangedSubviews(subviews)
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
        updateAddOnsStackView(viewModel: item.addOns)
        viewAddOnsStackView.isHidden = !item.hasAddOns
        configureChildProductPadding(isChildProduct: item.isChildProduct)
    }

    func configure(customAmountViewModel: OrderDetailsCustomAmountCellViewModel) {
        nameLabel.text = customAmountViewModel.name
        productImageView.image = customAmountViewModel.image
        priceLabel.text = customAmountViewModel.total
        subtitleLabel.text = Localization.customAmount
        viewAddOnsStackView.isHidden = true
    }
}

// MARK: Localization
private extension ProductDetailsTableViewCell {
    enum Localization {
        static let viewAddOns = NSLocalizedString("View Add-Ons", comment: "Title of the button on the order detail item to navigate to add-ons")
        static let customAmount = NSLocalizedString("orderDetails.customAmountsRow.subtitle",
                                                    value: "Custom Amount",
                                                    comment: "Subtitle of the custom amount row in order details")
    }

    enum Constants {
        static let childProductLeadingPadding: CGFloat = 44
    }
}
