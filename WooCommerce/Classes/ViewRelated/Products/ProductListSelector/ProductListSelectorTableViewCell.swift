import UIKit

final class ProductListSelectorTableViewCell: UITableViewCell {

    private lazy var circleImageView: UIImageView = {
        let image = UIImageView(frame: .zero)
        return image
    }()

    private lazy var productImageView: UIImageView = {
        let image = UIImageView(frame: .zero)
        return image
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()

    private lazy var detailsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()

    private lazy var skuLabel: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureBackground()
        configureSubviews()
        configureNameLabel()
        configureDetailsLabel()
        configureSkuLabel()
        configureProductImageView()
        configureCircleImageView()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension ProductListSelectorTableViewCell {
    func update(viewModel: ProductsTabProductViewModel, imageService: ImageService) {
        nameLabel.text = viewModel.createNameLabel()
        detailsLabel.text = viewModel.detailsString
        skuLabel.text = viewModel.skuString
        accessibilityIdentifier = viewModel.createNameLabel()

        productImageView.contentMode = .center
        if let productURLString = viewModel.imageUrl {
            imageService.downloadAndCacheImageForImageView(productImageView,
                                                           with: productURLString,
                                                           placeholder: .productsTabProductCellPlaceholderImage,
                                                           progressBlock: nil) { [weak self] (image, error) in
                                                            let success = image != nil && error == nil
                                                            if success {
                                                                self?.productImageView.contentMode = .scaleAspectFill
                                                            }
            }
        }

        // Selected state.
        let isSelected = viewModel.isSelected
        if isSelected {
            circleImageView.image = UIImage.checkCircleImage.applyTintColor(.primary)
        } else {
            circleImageView.image = UIImage.checkEmptyCircleImage
        }
    }
}

// MARK: - View configuration
//
private extension ProductListSelectorTableViewCell {
    func configureSubviews() {
        let contentStackView = createContentStackView()
        let stackView = UIStackView(arrangedSubviews: [circleImageView, productImageView, contentStackView])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center

        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    func createContentStackView() -> UIView {
        let contentStackView = UIStackView(arrangedSubviews: [nameLabel, detailsLabel, skuLabel])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        return contentStackView
    }

    func configureBackground() {
        backgroundColor = .listForeground

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    func configureNameLabel() {
        nameLabel.applyBodyStyle()
        nameLabel.numberOfLines = 0
    }

    func configureDetailsLabel() {
        detailsLabel.numberOfLines = 0
        detailsLabel.applySubheadlineStyle()
        detailsLabel.textColor = .secondaryLabel
    }

    func configureSkuLabel() {
        skuLabel.numberOfLines = 0
        skuLabel.applySubheadlineStyle()
        skuLabel.textColor = .secondaryLabel
    }

    func configureProductImageView() {
        productImageView.backgroundColor = Colors.imageBackgroundColor
        productImageView.tintColor = Colors.imagePlaceholderTintColor
        productImageView.layer.cornerRadius = Constants.productImageCornerRadius
        productImageView.clipsToBounds = true

        NSLayoutConstraint.activate([
            productImageView.widthAnchor.constraint(equalToConstant: Constants.productImageSize),
            productImageView.heightAnchor.constraint(equalToConstant: Constants.productImageSize),
        ])
    }

    func configureCircleImageView() {
        NSLayoutConstraint.activate([
            circleImageView.widthAnchor.constraint(equalToConstant: Constants.circleImageSize),
            circleImageView.heightAnchor.constraint(equalToConstant: Constants.circleImageSize),
        ])
    }
}

// MARK: - Constants
//
private extension ProductListSelectorTableViewCell {
    enum Constants {
        static let productImageCornerRadius: CGFloat = 4.0
        static let productImageSize: CGFloat = 48
        static let circleImageSize: CGFloat = 24
    }

    enum Colors {
        static let imageBorderColor = UIColor.border
        static let imagePlaceholderTintColor = UIColor.systemColor(.systemGray2)
        static let imageBackgroundColor = UIColor.listForeground
    }
}
