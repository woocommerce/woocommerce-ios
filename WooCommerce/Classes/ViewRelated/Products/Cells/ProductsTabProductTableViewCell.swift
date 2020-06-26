import UIKit
import Kingfisher

final class ProductsTabProductTableViewCell: UITableViewCell {
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

    /// We use a custom view isntead of the default separator as it's width varies depending on the image size, which varies depending on the screen size.
    private let bottomBorderView: UIView = {
        return UIView(frame: .zero)
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureBackground()
        configureSubviews()
        configureNameLabel()
        configureDetailsLabel()
        configureProductImageView()
        configureBottomBorderView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Border color is not automatically updated on trait collection changes and thus manually updated here.
        productImageView.layer.borderColor = Colors.imageBorderColor.cgColor
    }
}

extension ProductsTabProductTableViewCell: SearchResultCell {
    typealias SearchModel = ProductsTabProductViewModel

    func configureCell(searchModel: ProductsTabProductViewModel) {
        update(viewModel: searchModel, imageService: searchModel.imageService)
    }

    static func register(for tableView: UITableView) {
        tableView.register(self, forCellReuseIdentifier: reuseIdentifier)
    }
}

extension ProductsTabProductTableViewCell {
    func update(viewModel: ProductsTabProductViewModel, imageService: ImageService) {
        nameLabel.text = viewModel.name

        detailsLabel.attributedText = viewModel.detailsAttributedString

        productImageView.contentMode = .center
        productImageView.image = .productsTabProductCellPlaceholderImage
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
    }
}

private extension ProductsTabProductTableViewCell {
    func configureSubviews() {
        let contentStackView = createContentStackView()
        let stackView = UIStackView(arrangedSubviews: [productImageView, contentStackView])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .leading

        stackView.translatesAutoresizingMaskIntoConstraints = false
        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        contentView.addSubview(bottomBorderView)
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))

        NSLayoutConstraint.activate([
            bottomBorderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorderView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func createContentStackView() -> UIView {
        let contentStackView = UIStackView(arrangedSubviews: [nameLabel, detailsLabel])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 4
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
        nameLabel.numberOfLines = 2
    }

    func configureDetailsLabel() {
        detailsLabel.numberOfLines = 1
    }

    func configureProductImageView() {

        productImageView.backgroundColor = Colors.imageBackgroundColor
        productImageView.tintColor = Colors.imagePlaceholderTintColor
        productImageView.layer.cornerRadius = Constants.cornerRadius
        productImageView.layer.borderWidth = Constants.borderWidth
        productImageView.layer.borderColor = Colors.imageBorderColor.cgColor
        productImageView.clipsToBounds = true

        NSLayoutConstraint.activate([
            // This multiplier matches the required size(37.5pt) for a 375pt(as per designs) content view width
            productImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.1),
            productImageView.widthAnchor.constraint(equalTo: productImageView.heightAnchor)
            ])
    }

    func configureBottomBorderView() {
        bottomBorderView.backgroundColor = .systemColor(.separator)
    }
}

/// Constants
///
private extension ProductsTabProductTableViewCell {
    enum Constants {
        static let cornerRadius = CGFloat(2.0)
        static let borderWidth = CGFloat(0.5)
    }

    enum Colors {
        static let imageBorderColor = UIColor.border
        static let imagePlaceholderTintColor = UIColor.systemColor(.systemGray2)
        static let imageBackgroundColor = UIColor.listForeground
    }
}
