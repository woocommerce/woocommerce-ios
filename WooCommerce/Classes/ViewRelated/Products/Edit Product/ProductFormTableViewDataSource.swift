import UIKit
import Yosemite

private extension ProductFormSection.SettingsRow.ViewModel {
    func toCellViewModel() -> ImageAndTitleAndTextTableViewCell.ViewModel {
        return ImageAndTitleAndTextTableViewCell.ViewModel(title: title,
                                                           titleTintColor: tintColor,
                                                           text: details,
                                                           textTintColor: tintColor,
                                                           image: icon,
                                                           imageTintColor: tintColor ?? .textSubtle,
                                                           numberOfLinesForText: numberOfLinesForDetails,
                                                           isActionable: isActionable,
                                                           showsDisclosureIndicator: isActionable,
                                                           showsSeparator: !hideSeparator)
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

    var openLinkedProductsAction: (() -> Void)?
    var reloadLinkedPromoAction: (() -> Void)?
    var descriptionAIAction: (() -> Void)?
    var openAILegalPageAction: ((URL) -> Void)?

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
        case .images(let editable, let isStorePublic, let allowsMultipleImages, let isVariation):
            configureImages(cell: cell,
                            isEditable: editable,
                            isStorePublic: isStorePublic,
                            allowsMultipleImages: allowsMultipleImages,
                            isVariation: isVariation)
        case .linkedProductsPromo(let viewModel):
            configureLinkedProductsPromo(cell: cell, viewModel: viewModel)
        case .name(let name, let editable, let productStatus):
            configureName(cell: cell, name: name, isEditable: editable, productStatus: productStatus)
        case .variationName(let name):
            configureReadonlyName(cell: cell, name: name)
        case .description(let description, let editable, let isAIEnabled):
            configureDescription(cell: cell, description: description, isEditable: editable, isAIEnabled: isAIEnabled)
        case .descriptionAI:
            configureDescriptionAI(cell: cell)
        case .learnMoreAboutAI:
            configureLearnMoreAI(cell: cell)
        case .separator:
            configureSeparator(cell: cell)
        case .promoteWithBlaze:
            configurePromoteWithBlaze(cell: cell)
        }
    }

    func configureImages(cell: UITableViewCell, isEditable: Bool, isStorePublic: Bool, allowsMultipleImages: Bool, isVariation: Bool) {
        // only show images row if it's a .org site or a public .com site. Private .com site will see a banner.
        guard isStorePublic else {
            guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
                fatalError("Expected cell to be of type ImageAndTitleAndTextTableViewCell for the product images cell when store is private on WP.com")
            }
            let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(
                title: Localization.wpComStoreNotPublicTitle,
                titleFontStyle: .body,
                titleTintColor: .text,
                text: Localization.wpComStoreNotPublicText,
                textTintColor: .textLink,
                image: .infoOutlineImage,
                imageTintColor: .text,
                numberOfLinesForTitle: 0,
                numberOfLinesForText: 0,
                isActionable: true,
                showsDisclosureIndicator: false,
                showsSeparator: true
            )

            cell.updateUI(viewModel: viewModel)
            cell.contentView.backgroundColor = .warningBackground
            return
        }

        // display product images
        guard let cell = cell as? ProductImagesHeaderTableViewCell else {
            fatalError("Expected cell to be of type ProductImagesHeaderTableViewCell for displaying product images")
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
            if allowsMultipleImages {
                cell.configure(with: productImageStatuses,
                               config: .addImages,
                               productUIImageLoader: productUIImageLoader)
            } else {
                cell.configure(with: productImageStatuses, config: .images, productUIImageLoader: productUIImageLoader)
            }
        }
        else {
            cell.configure(with: productImageStatuses, config: .extendedAddImages(isVariation: isVariation), productUIImageLoader: productUIImageLoader)
        }
        cell.onImageSelected = { [weak self] (productImage, indexPath) in
            self?.onAddImage?()
        }
        cell.onAddImage = { [weak self] in
            self?.onAddImage?()
        }
    }

    func configureName(cell: UITableViewCell, name: String?, isEditable: Bool, productStatus: ProductStatus) {
        if isEditable {
            configureEditableName(cell: cell, name: name, productStatus: productStatus)
        } else {
            configureReadonlyName(cell: cell, name: name ?? "")
        }
    }

    func configureEditableName(cell: UITableViewCell, name: String?, productStatus: ProductStatus) {
        guard let cell = cell as? LabeledTextViewTableViewCell else {
            fatalError()
        }

        cell.accessoryType = .none
        cell.accessibilityIdentifier = "product-title"

        let placeholder = NSLocalizedString("Title", comment: "Placeholder in the Product Title row on Product form screen.")

        let cellViewModel = LabeledTextViewTableViewCell.ViewModel(text: name,
                                                                   productStatus: productStatus,
                                                                   placeholder: placeholder,
                                                                   textViewMinimumHeight: 10.0,
                                                                   isScrollEnabled: false,
                                                                   onNameChange: { [weak self] (newName) in self?.onNameChange?(newName) },
                                                                   style: .headline)
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

    func configureDescription(cell: UITableViewCell, description: String?, isEditable: Bool, isAIEnabled: Bool) {
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
            cell.accessibilityIdentifier = "product-description"
        }
        if isEditable {
            cell.accessoryType = .disclosureIndicator
        }
        if isAIEnabled {
            cell.hideSeparator()
        }
    }

    func configureDescriptionAI(cell: UITableViewCell) {
        guard let cell = cell as? ButtonTableViewCell else {
            fatalError()
        }
        let title = NSLocalizedString(
            "Write with AI",
            comment: "Product description AI row on Product form screen when the feature is available."
        )
        cell.configure(style: .subtle,
                       title: title,
                       image: .sparklesImage,
                       accessibilityIdentifier: "product-description-ai",
                       topSpacing: 6,
                       bottomSpacing: 0) { [weak self] in
            self?.descriptionAIAction?()
        }
        cell.accessoryType = .none
        cell.hideSeparator()
    }

    func configureLearnMoreAI(cell: UITableViewCell) {
        guard let cell = cell as? TextViewTableViewCell else {
            fatalError("Unexpected table view cell for the AI legal cell")
        }
        let attributedText = {
            let content = String.localizedStringWithFormat(Localization.legalText, Localization.learnMore)
            let font: UIFont = .caption1
            let foregroundColor: UIColor = .secondaryLabel
            let linkColor: UIColor = .accent
            let linkContent = Localization.learnMore

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let attributedString = NSMutableAttributedString(
                string: content,
                attributes: [.font: font,
                             .foregroundColor: foregroundColor,
                             .paragraphStyle: paragraphStyle,
                            ]
            )
            let legalLink = NSAttributedString(string: linkContent,
                                               attributes: [.font: font,
                                                            .foregroundColor: linkColor,
                                                            .underlineStyle: NSUnderlineStyle.single.rawValue,
                                                            .underlineColor: linkColor,
                                                            .link: Constants.legalURL])
            attributedString.replaceFirstOccurrence(of: linkContent, with: legalLink)
            return attributedString
        }()
        cell.configure(with: .init(attributedText: attributedText,
                                   textViewMinimumHeight: Constants.learnMoreTextHeight,
                                   isEditable: false,
                                   isSelectable: true,
                                   isScrollEnabled: false,
                                   style: .caption,
                                   edgeInsets: Constants.learnMoreTextInsets,
                                   onLinkTapped: { [weak self] url in
            self?.openAILegalPageAction?(url)
        }))
        cell.selectionStyle = .none
        cell.hideSeparator()
    }

    func configurePromoteWithBlaze(cell: UITableViewCell) {
        guard let cell = cell as? LeftImageTableViewCell else {
            fatalError("Unexpected table view cell for the promote with Blaze cell")
        }
        let title = NSLocalizedString(
            "productFormTableViewDataSource.promoteWithBlazeButton",
            value: "Promote with Blaze",
            comment: "Label for button on product form to open Blaze flow"
        )

        cell.configure(
            image: .blaze.resize(to: Constants.blazeButtonIconSize),
            text: title,
            textColor: .accent
        )
        cell.hideSeparator()
    }

    func configureSeparator(cell: UITableViewCell) {
        guard let cell = cell as? SpacerTableViewCell else {
            fatalError("Unexpected table view cell for the separator cell")
        }
        cell.selectionStyle = .none
        cell.backgroundColor = .listBackground
        cell.hideSeparator()
        cell.configure(height: Constants.settingsHeaderHeight)
    }

    func configureLinkedProductsPromo(cell: UITableViewCell, viewModel: FeatureAnnouncementCardViewModel) {
        guard let cell = cell as? FeatureAnnouncementCardCell else {
            fatalError()
        }

        cell.configure(with: viewModel)

        cell.dismiss = { [weak self] in
            self?.reloadLinkedPromoAction?()
        }
        cell.callToAction = { [weak self] in
            self?.openLinkedProductsAction?()
        }

        cell.selectionStyle = .none
        cell.hideSeparator()
    }
}

// MARK: Configure rows in Settings Fields Section
//
private extension ProductFormTableViewDataSource {
    func configureCellInSettingsFieldsSection(_ cell: UITableViewCell, row: ProductFormSection.SettingsRow) {
        switch row {
        case .price(let viewModel, _),
             .customFields(let viewModel),
             .inventory(let viewModel, _),
             .productType(let viewModel, _),
             .shipping(let viewModel, _),
             .addOns(let viewModel, _),
             .categories(let viewModel, _),
             .tags(let viewModel, _),
             .shortDescription(let viewModel, _),
             .externalURL(let viewModel, _),
             .sku(let viewModel, _),
             .groupedProducts(let viewModel, _),
             .downloadableFiles(let viewModel, _),
             .linkedProducts(let viewModel, _),
             .variations(let viewModel),
             .attributes(let viewModel, _),
             .bundledProducts(let viewModel, _),
             .components(let viewModel, _),
             .subscriptionFreeTrial(let viewModel, _),
             .subscriptionExpiry(let viewModel, _),
             .quantityRules(let viewModel):
            configureSettings(cell: cell, viewModel: viewModel)
        case .reviews(let viewModel, let ratingCount, let averageRating):
            configureReviews(cell: cell, viewModel: viewModel, ratingCount: ratingCount, averageRating: averageRating)
        case .status(let viewModel, _):
            configureSettingsRowWithASwitch(cell: cell, viewModel: viewModel)
        case .noPriceWarning(let viewModel),
             .noVariationsWarning(let viewModel):
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
        cell.accessibilityIdentifier = "product-review-cell"
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
                                isActionable: false,
                                showsSeparator: false))
    }
}

private extension ProductFormTableViewDataSource {
    enum Constants {
        static let legalURL = URL(string: "https://automattic.com/ai-guidelines/")!
        static let learnMoreTextHeight: CGFloat = 16
        static let learnMoreTextInsets: UIEdgeInsets = .init(top: 4, left: 0, bottom: 4, right: 0)
        static let settingsHeaderHeight = CGFloat(16)
        static let blazeButtonIconSize = CGSize(width: 20, height: 20)
    }
    enum Localization {
        static let legalText = NSLocalizedString(
            "Powered by AI. %1$@.",
            comment: "Label to indicate AI-generated content in the product detail screen. " +
            "Reads: Powered by AI. Learn more."
        )
        static let learnMore = NSLocalizedString(
            "Learn more",
            comment: "Title for the link to open the legal URL for AI-generated content in the product detail screen"
        )
        static let wpComStoreNotPublicTitle = NSLocalizedString(
            "productFormTableViewDataSource.wpComStoreNotPublicTitle",
            value: "The images are unavailable because your site is marked Private. You can change this by switching to Coming Soon mode.",
            comment: "Title message indicating that images are unavailable because the site is private."
        )
        static let wpComStoreNotPublicText = NSLocalizedString(
            "productFormTableViewDataSource.wpComStoreNotPublicText",
            value: "Tap to learn more.",
            comment: "Text message prompting the user to tap to learn more about changing the privacy setting."
        )
    }
}
