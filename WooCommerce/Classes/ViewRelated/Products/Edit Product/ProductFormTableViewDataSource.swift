import UIKit
import Yosemite

private extension ProductFormSection.SettingsRow.ViewModel {
    func toCellViewModel() -> ImageAndTitleAndTextTableViewCell.ViewModel {
        return ImageAndTitleAndTextTableViewCell.ViewModel(title: title,
                                                           text: details,
                                                           textTintColor: tintColor,
                                                           image: icon,
                                                           imageTintColor: tintColor ?? .textSubtle,
                                                           numberOfLinesForText: numberOfLinesForDetails,
                                                           isActionable: isActionable)
    }
}

/// Configures the sections and rows of Product form table view based on the view model.
///
final class ProductFormTableViewDataSource: NSObject {
    private let viewModel: ProductFormTableViewModel
    private var onNameChange: ((_ name: String?) -> Void)?
    private var onStatusChange: ((_ isEnabled: Bool) -> Void)?
    private var onAddImage: (() -> Void)?

    private let productImageStatuses: [ProductImageStatus]
    private let productUIImageLoader: ProductUIImageLoader

    init(viewModel: ProductFormTableViewModel,
         productImageStatuses: [ProductImageStatus],
         productUIImageLoader: ProductUIImageLoader) {
        self.viewModel = viewModel
        self.productImageStatuses = productImageStatuses
        self.productUIImageLoader = productUIImageLoader
        super.init()
    }

    func configureActions(onNameChange: ((_ name: String?) -> Void)?, onStatusChange: ((_ isEnabled: Bool) -> Void)?, onAddImage: @escaping () -> Void) {
        self.onNameChange = onNameChange
        self.onStatusChange = onStatusChange
        self.onAddImage = onAddImage
    }
}

extension ProductFormTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = viewModel.sections[section]
        switch section {
        case .primaryFields(let rows):
            return rows.count
        case .settings(let rows):
            return rows.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = viewModel.sections[indexPath.section]
        let reuseIdentifier = section.reuseIdentifier(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        configure(cell, section: section, indexPath: indexPath)
        return cell
    }
}

private extension ProductFormTableViewDataSource {
    func configure(_ cell: UITableViewCell, section: ProductFormSection, indexPath: IndexPath) {
        switch section {
        case .primaryFields(let rows):
            configureCellInPrimaryFieldsSection(cell, row: rows[indexPath.row])
        case .settings(let rows):
            configureCellInSettingsFieldsSection(cell, row: rows[indexPath.row])
        }
    }
}

// MARK: Configure rows in Primary Fields Section
//
private extension ProductFormTableViewDataSource {
    func configureCellInPrimaryFieldsSection(_ cell: UITableViewCell, row: ProductFormSection.PrimaryFieldRow) {
        switch row {
        case .images(let editable):
            configureImages(cell: cell, isEditable: editable)
        case .name(let name, let editable):
            configureName(cell: cell, name: name, isEditable: editable)
        case .variationName(let name):
            configureReadonlyName(cell: cell, name: name)
        case .description(let description, let editable):
            configureDescription(cell: cell, description: description, isEditable: editable)
        }
    }

    func configureImages(cell: UITableViewCell, isEditable: Bool) {
        guard let cell = cell as? ProductImagesHeaderTableViewCell else {
            fatalError()
        }

        defer {
            cell.accessibilityLabel = NSLocalizedString(
                "List of images of the product",
                comment: "VoiceOver accessibility hint, informing the user about the image section header of a product in product detail screen."
            )
        }

        guard isEditable else {
            cell.configure(with: productImageStatuses,
                           config: .images,
                           productUIImageLoader: productUIImageLoader)
            return
        }

        if productImageStatuses.count > 0 {
            cell.configure(with: productImageStatuses, config: .addImages, productUIImageLoader: productUIImageLoader)
        }
        else {
            cell.configure(with: productImageStatuses, config: .extendedAddImages, productUIImageLoader: productUIImageLoader)
        }

        cell.onImageSelected = { [weak self] (productImage, indexPath) in
            self?.onAddImage?()
        }
        cell.onAddImage = { [weak self] in
            self?.onAddImage?()
        }
    }

    func configureName(cell: UITableViewCell, name: String?, isEditable: Bool) {
        if isEditable {
            configureEditableName(cell: cell, name: name)
        } else {
            configureReadonlyName(cell: cell, name: name ?? "")
        }
    }

    func configureEditableName(cell: UITableViewCell, name: String?) {
        guard let cell = cell as? TextViewTableViewCell else {
            fatalError()
        }

        cell.accessoryType = .none

        let placeholder = NSLocalizedString("Title", comment: "Placeholder in the Product Title row on Product form screen.")

        let cellViewModel = TextViewTableViewCell.ViewModel(text: name,
                                                            placeholder: placeholder,
                                                            textViewMinimumHeight: 10.0,
                                                            isScrollEnabled: false,
                                                            onTextChange: { [weak self] (newName) in
            self?.onNameChange?(newName)
            },
                                                            style: .headline,
                                                            edgeInsets: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))

        cell.configure(with: cellViewModel)
        cell.accessibilityLabel = NSLocalizedString(
            "Title of the product",
            comment: "VoiceOver accessibility hint, informing the user about the title of a product in product detail screen."
        )
    }

    func configureReadonlyName(cell: UITableViewCell, name: String) {
        guard let cell = cell as? BasicTableViewCell else {
            fatalError()
        }

        cell.accessoryType = .none
        cell.textLabel?.text = name
        cell.textLabel?.applyHeadlineStyle()
        cell.textLabel?.textColor = .text
        cell.textLabel?.numberOfLines = 0
    }

    func configureDescription(cell: UITableViewCell, description: String?, isEditable: Bool) {
        if let description = description, description.isEmpty == false {
            guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
                fatalError()
            }
            let title = NSLocalizedString("Description",
                                          comment: "Title in the Product description row on Product form screen when the description is non-empty.")
            let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: title, text: description, isActionable: isEditable)
            cell.updateUI(viewModel: viewModel)
        } else {
            guard let cell = cell as? BasicTableViewCell else {
                fatalError()
            }
            let placeholder = NSLocalizedString("Describe your product", comment: "Placeholder in the Product description row on Product form screen.")
            cell.textLabel?.text = placeholder
            cell.textLabel?.applyBodyStyle()
            cell.textLabel?.textColor = .textSubtle
        }
        if isEditable {
            cell.accessoryType = .disclosureIndicator
        }
    }
}

// MARK: Configure rows in Settings Fields Section
//
private extension ProductFormTableViewDataSource {
    func configureCellInSettingsFieldsSection(_ cell: UITableViewCell, row: ProductFormSection.SettingsRow) {
        switch row {
        case .price(let viewModel, _),
             .inventory(let viewModel, _),
             .productType(let viewModel, _),
             .shipping(let viewModel, _),
             .categories(let viewModel, _),
             .tags(let viewModel, _),
             .shortDescription(let viewModel, _),
             .externalURL(let viewModel, _),
             .sku(let viewModel, _),
             .groupedProducts(let viewModel, _),
             .downloadableFiles(let viewModel),
             .linkedProducts(let viewModel, _),
             .variations(let viewModel),
             .attributes(let viewModel, _):
            configureSettings(cell: cell, viewModel: viewModel)
        case .reviews(let viewModel, let ratingCount, let averageRating):
            configureReviews(cell: cell, viewModel: viewModel, ratingCount: ratingCount, averageRating: averageRating)
        case .status(let viewModel, _):
            configureSettingsRowWithASwitch(cell: cell, viewModel: viewModel)
        case .noPriceWarning(let viewModel):
            configureWarningRow(cell: cell, viewModel: viewModel)
        }
    }

    func configureSettings(cell: UITableViewCell, viewModel: ProductFormSection.SettingsRow.ViewModel) {
        guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }
        cell.updateUI(viewModel: viewModel.toCellViewModel())
    }

    func configureReviews(cell: UITableViewCell,
                          viewModel: ProductFormSection.SettingsRow.ViewModel,
                          ratingCount: Int,
                          averageRating: String) {
        guard let cell = cell as? ProductReviewsTableViewCell else {
            fatalError()
        }

        cell.configure(image: viewModel.icon,
                       title: viewModel.title ?? "",
                       details: viewModel.details ?? "",
                       ratingCount: ratingCount,
                       averageRating: averageRating)
        cell.accessoryType = .disclosureIndicator
    }

    func configureSettingsRowWithASwitch(cell: UITableViewCell, viewModel: ProductFormSection.SettingsRow.SwitchableViewModel) {
        guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }

        let switchableViewModel = ImageAndTitleAndTextTableViewCell.SwitchableViewModel(viewModel: viewModel.viewModel.toCellViewModel(),
                                                                                        isSwitchOn: viewModel.isSwitchOn,
                                                                                        isActionable: viewModel.isActionable) { [weak self] isSwitchOn in
                                                                                            self?.onStatusChange?(isSwitchOn)
        }
        cell.updateUI(switchableViewModel: switchableViewModel)
    }

    func configureWarningRow(cell warningCell: UITableViewCell, viewModel: ProductFormSection.SettingsRow.WarningViewModel) {
        guard let cell = warningCell as? ImageAndTitleAndTextTableViewCell else {
            fatalError("Unexpected cell type \(warningCell) for view model: \(viewModel)")
        }
        cell.update(with: .warning,
                    data: .init(title: viewModel.title,
                                image: viewModel.icon,
                                numberOfLinesForTitle: 0,
                                isActionable: false))
    }
}
