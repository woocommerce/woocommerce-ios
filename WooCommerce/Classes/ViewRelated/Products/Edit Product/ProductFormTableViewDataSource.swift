import UIKit
import Yosemite

private extension ProductFormSection.SettingsRow.ViewModel {
    func toCellViewModel() -> ImageAndTitleAndTextTableViewCell.ViewModel {
        return ImageAndTitleAndTextTableViewCell.ViewModel(title: title,
                                                           text: details,
                                                           image: icon,
                                                           imageTintColor: .textSubtle,
                                                           numberOfLinesForText: numberOfLinesForDetails,
                                                           isActionable: isActionable)
    }
}

/// Configures the sections and rows of Product form table view based on the view model.
///
final class ProductFormTableViewDataSource: NSObject {
    private let viewModel: ProductFormTableViewModel
    private let canEditImages: Bool
    private var onNameChange: ((_ name: String?) -> Void)?
    private var onStatusChange: ((_ isEnabled: Bool) -> Void)?
    private var onAddImage: (() -> Void)?

    private let productImageStatuses: [ProductImageStatus]
    private let productUIImageLoader: ProductUIImageLoader

    init(viewModel: ProductFormTableViewModel,
         productImageStatuses: [ProductImageStatus],
         productUIImageLoader: ProductUIImageLoader,
         canEditImages: Bool) {
        self.viewModel = viewModel
        self.canEditImages = canEditImages
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
        case .images:
            configureImages(cell: cell)
        case .name(let name):
            configureName(cell: cell, name: name)
        case .variationName(let name):
            configureVariationName(cell: cell, name: name)
        case .description(let description):
            configureDescription(cell: cell, description: description)
        }
    }

    func configureImages(cell: UITableViewCell) {
        guard let cell = cell as? ProductImagesHeaderTableViewCell else {
            fatalError()
        }

        guard canEditImages else {
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
            ServiceLocator.analytics.track(.productDetailAddImageTapped)
            self?.onAddImage?()
        }
        cell.onAddImage = { [weak self] in
            ServiceLocator.analytics.track(.productDetailAddImageTapped)
            self?.onAddImage?()
        }
    }

    func configureName(cell: UITableViewCell, name: String?) {
        guard let cell = cell as? TextFieldTableViewCell else {
            fatalError()
        }

        cell.accessoryType = .none

        let placeholder = NSLocalizedString("Title", comment: "Placeholder in the Product Title row on Product form screen.")
        let viewModel = TextFieldTableViewCell.ViewModel(text: name, placeholder: placeholder, onTextChange: { [weak self] newName in
            self?.onNameChange?(newName)
            }, onTextDidBeginEditing: {
                ServiceLocator.analytics.track(.productDetailViewProductNameTapped)
        }, inputFormatter: nil, keyboardType: .default)
        cell.configure(viewModel: viewModel)
    }

    func configureVariationName(cell: UITableViewCell, name: String) {
        guard let cell = cell as? BasicTableViewCell else {
            fatalError()
        }

        cell.accessoryType = .none
        cell.textLabel?.text = name
        cell.textLabel?.applyHeadlineStyle()
        cell.textLabel?.textColor = .text
        cell.textLabel?.numberOfLines = 0
    }

    func configureDescription(cell: UITableViewCell, description: String?) {
        if let description = description, description.isEmpty == false {
            guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
                fatalError()
            }
            let title = NSLocalizedString("Description",
                                          comment: "Title in the Product description row on Product form screen when the description is non-empty.")
            let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: title, text: description)
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
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: Configure rows in Settings Fields Section
//
private extension ProductFormTableViewDataSource {
    func configureCellInSettingsFieldsSection(_ cell: UITableViewCell, row: ProductFormSection.SettingsRow) {
        switch row {
        case .price(let viewModel),
             .inventory(let viewModel),
             .shipping(let viewModel),
             .categories(let viewModel),
             .tags(let viewModel),
             .briefDescription(let viewModel),
             .externalURL(let viewModel),
             .sku(let viewModel),
             .groupedProducts(let viewModel),
             .variations(let viewModel):
            configureSettings(cell: cell, viewModel: viewModel)
        case .reviews(let viewModel, let ratingCount, let averageRating):
            configureReviews(cell: cell, viewModel: viewModel, ratingCount: ratingCount, averageRating: averageRating)
        case .status(let viewModel):
            configureSettingsRowWithASwitch(cell: cell, viewModel: viewModel)
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
        if ratingCount > 0 {
            cell.accessoryType = .disclosureIndicator
        }
    }

    func configureSettingsRowWithASwitch(cell: UITableViewCell, viewModel: ProductFormSection.SettingsRow.SwitchableViewModel) {
        guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }

        let switchableViewModel = ImageAndTitleAndTextTableViewCell.SwitchableViewModel(viewModel: viewModel.viewModel.toCellViewModel(),
                                                                                        isSwitchOn: viewModel.isSwitchOn) { [weak self] isSwitchOn in
                                                                                            self?.onStatusChange?(isSwitchOn)
        }
        cell.updateUI(switchableViewModel: switchableViewModel)
    }
}
