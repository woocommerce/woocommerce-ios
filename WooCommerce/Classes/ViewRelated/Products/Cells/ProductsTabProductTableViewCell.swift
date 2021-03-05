import UIKit

final class ProductsTabProductTableViewCell: UITableViewCell {
    private lazy var productImageView: UIImageView = {
        let image = UIImageView(frame: .zero)
        return image
    }()

    private var selectedProductImageOverlayView: UIView?

    /// ProductImageView.width == 0.1*Cell.width
    private var productImageViewRelationalWidthConstraint: NSLayoutConstraint?

    /// ProductImageView.height == Cell.height
    private var productImageViewFixedHeightConstraint: NSLayoutConstraint?

    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()

    private lazy var detailsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()

    /// We use a custom view instead of the default separator as it's width varies depending on the image size, which varies depending on the screen size.
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
        tableView.register(self)
    }
}

extension ProductsTabProductTableViewCell {
    func update(viewModel: ProductsTabProductViewModel, imageService: ImageService) {
        nameLabel.text = viewModel.name

        detailsLabel.attributedText = viewModel.detailsAttributedString

        productImageView.contentMode = .center
        if viewModel.isDraggable {
            configureProductImageViewForSmallIcons()
            productImageView.image = .alignJustifyImage
            productImageView.layer.borderWidth = 0
        } else {
            configureProductImageViewForBigImages()
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

        // Selected state.
        let isSelected = viewModel.isSelected
        if isSelected {
            configureSelectedProductImageOverlayView()
        } else {
            selectedProductImageOverlayView?.removeFromSuperview()
            selectedProductImageOverlayView = nil
        }
        let selectedBackgroundColor = isSelected ? UIColor.primary.withAlphaComponent(0.2): .listForeground
        backgroundColor = selectedBackgroundColor
    }

    func configureAccessoryDeleteButton(onTap: @escaping () -> Void) {
        let deleteButton = UIButton(type: .detailDisclosure)
        deleteButton.setImage(.deleteCellImage, for: .normal)
        deleteButton.tintColor = .systemColor(.tertiaryLabel)
        deleteButton.on(.touchUpInside) { _ in
            onTap()
        }
        accessoryView = deleteButton
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

        // Not initially enabled, saved for possible compact icon case
        productImageViewFixedHeightConstraint = productImageView.heightAnchor.constraint(equalTo: stackView.heightAnchor)

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
        detailsLabel.numberOfLines = 0
    }

    func configureProductImageView() {

        productImageView.backgroundColor = Colors.imageBackgroundColor
        productImageView.tintColor = Colors.imagePlaceholderTintColor
        productImageView.layer.cornerRadius = Constants.cornerRadius
        productImageView.layer.borderWidth = Constants.borderWidth
        productImageView.layer.borderColor = Colors.imageBorderColor.cgColor
        productImageView.clipsToBounds = true

        // This multiplier matches the required size(37.5pt) for a 375pt(as per designs) content view width
        let widthConstraint = productImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.1)
        productImageViewRelationalWidthConstraint = widthConstraint

        NSLayoutConstraint.activate([
            widthConstraint,
            productImageView.widthAnchor.constraint(equalTo: productImageView.heightAnchor)
        ])
    }

    func configureProductImageViewForBigImages() {
        productImageViewRelationalWidthConstraint?.isActive = true
        productImageViewFixedHeightConstraint?.isActive = false
    }

    func configureProductImageViewForSmallIcons() {
        productImageViewRelationalWidthConstraint?.isActive = false
        productImageViewFixedHeightConstraint?.isActive = true
    }

    func configureBottomBorderView() {
        bottomBorderView.backgroundColor = .systemColor(.separator)
    }

    func configureSelectedProductImageOverlayView() {
        guard selectedProductImageOverlayView == nil else {
            return
        }

        let view = UIView(frame: .zero)
        view.backgroundColor = .primary
        view.translatesAutoresizingMaskIntoConstraints = false
        let checkmarkImage = UIImage.checkmarkInCellImageOverlay
        let checkmarkImageView = UIImageView(image: checkmarkImage)
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(checkmarkImageView)
        view.pinSubviewAtCenter(checkmarkImageView)
        selectedProductImageOverlayView = view

        productImageView.addSubview(view)
        productImageView.pinSubviewToAllEdges(view)
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

#if canImport(SwiftUI) && DEBUG

import SwiftUI

import Yosemite

private struct ProductsTabProductTableViewCellRepresentable: UIViewRepresentable {
    let viewModel: ProductsTabProductViewModel

    func makeUIView(context: Context) -> ProductsTabProductTableViewCell {
        .init(style: .default, reuseIdentifier: "cell")
    }

    func updateUIView(_ view: ProductsTabProductTableViewCell, context: Context) {
        view.update(viewModel: viewModel, imageService: ServiceLocator.imageService)
    }
}

struct ProductsTabProductTableViewCell_Previews: PreviewProvider {
    private static var nonSelectedViewModel = ProductsTabProductViewModel(product: Product(), isSelected: false)
    private static var selectedViewModel = ProductsTabProductViewModel(product: Product().copy(statusKey: ProductStatus.pending.rawValue),
                                                                       isSelected: true)

    private static func makeStack() -> some View {
        VStack {
            ProductsTabProductTableViewCellRepresentable(viewModel: nonSelectedViewModel)
            ProductsTabProductTableViewCellRepresentable(viewModel: selectedViewModel)
        }
        .background(Color(UIColor.listForeground))
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 320, height: 150))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 320, height: 150))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 320, height: 400))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
