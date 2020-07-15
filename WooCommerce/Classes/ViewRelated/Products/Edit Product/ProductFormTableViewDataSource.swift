import UIKit
import Yosemite

private extension ProductFormSection.SettingsRow.ViewModel {
    func toCellViewModel() -> ImageAndTitleAndTextTableViewCell.ViewModel {
        return ImageAndTitleAndTextTableViewCell.ViewModel(title: title,
                                                           text: details,
                                                           image: icon,
                                                           imageTintColor: .textSubtle,
                                                           numberOfLinesForText: numberOfLinesForDetails)
    }
}

/// Configures the sections and rows of Product form table view based on the view model.
///
final class ProductFormTableViewDataSource: NSObject {
    private let viewModel: ProductFormTableViewModel
    private let canEditImages: Bool
    private var onNameChange: ((_ name: String?) -> Void)?
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

    func configureActions(onNameChange: ((_ name: String?) -> Void)?, onAddImage: @escaping () -> Void) {
        self.onNameChange = onNameChange
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
        case .images(let product):
            configureImages(cell: cell, product: product)
        case .name(let name):
            configureName(cell: cell, name: name)
        case .description(let description):
            configureDescription(cell: cell, description: description)
        }
    }

    func configureImages(cell: UITableViewCell, product: Product) {
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

        cell.onImageSelected = { (productImage, indexPath) in
            // TODO: open image detail
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
        guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }
        switch row {
        case .price(let viewModel), .inventory(let viewModel), .shipping(let viewModel), .categories(let viewModel), .tags(let viewModel),
             .briefDescription(let viewModel), .externalURL(let viewModel), .sku(let viewModel), .groupedProducts(let viewModel), .variations(let viewModel):
            configureSettings(cell: cell, viewModel: viewModel)
        }
    }

    func configureSettings(cell: ImageAndTitleAndTextTableViewCell, viewModel: ProductFormSection.SettingsRow.ViewModel) {
        cell.updateUI(viewModel: viewModel.toCellViewModel())
        cell.accessoryType = .disclosureIndicator
    }
}
