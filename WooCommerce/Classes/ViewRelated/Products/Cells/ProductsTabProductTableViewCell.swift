import UIKit

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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureBackground()
        configureSubviews()
        configureNameLabel()
        configureDetailsLabel()
        configureProductImageView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProductsTabProductTableViewCell: SearchResultCell {
    typealias SearchModel = ProductsTabProductViewModel

    func configureCell(searchModel: ProductsTabProductViewModel) {
        update(viewModel: searchModel)
    }

    static func register(for tableView: UITableView) {
        tableView.register(self, forCellReuseIdentifier: reuseIdentifier)
    }
}

extension ProductsTabProductTableViewCell {
    func update(viewModel: ProductsTabProductViewModel) {
        nameLabel.text = viewModel.name

        detailsLabel.attributedText = viewModel.detailsAttributedString

        productImageView.contentMode = .center
        productImageView.image = .productsTabProductCellPlaceholderImage
        if let productURLString = viewModel.imageUrl {
            productImageView.downloadImage(from: URL(string: productURLString), placeholderImage: nil, success: { [weak self] _ in
                self?.productImageView.contentMode = .scaleAspectFill
            })
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
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    func createContentStackView() -> UIView {
        let contentStackView = UIStackView(arrangedSubviews: [nameLabel, detailsLabel])
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
        nameLabel.numberOfLines = 2
    }

    func configureDetailsLabel() {
        detailsLabel.numberOfLines = 1
    }

    func configureProductImageView() {

        productImageView.layer.cornerRadius = CGFloat(2.0)
        productImageView.layer.borderWidth = 1
        productImageView.layer.borderColor = UIColor.listSmallIcon.cgColor
        productImageView.clipsToBounds = true

        NSLayoutConstraint.activate([
            productImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.1),
            productImageView.widthAnchor.constraint(equalTo: productImageView.heightAnchor)
            ])
    }
}
