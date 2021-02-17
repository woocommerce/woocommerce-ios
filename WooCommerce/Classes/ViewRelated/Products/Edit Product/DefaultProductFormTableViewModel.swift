import UIKit
import Yosemite

/// The Product form contains 2 sections: primary fields, and details.
struct DefaultProductFormTableViewModel: ProductFormTableViewModel {

    private(set) var sections: [ProductFormSection] = []
    private let currency: String
    private let currencyFormatter: CurrencyFormatter

    // Timezone of the website
    //
    var siteTimezone: TimeZone = TimeZone.siteTimezone

    private let isAddProductVariationsEnabled: Bool

    init(product: ProductFormDataModel,
         actionsFactory: ProductFormActionsFactoryProtocol,
         currency: String,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.currency = currency
        self.currencyFormatter = currencyFormatter
        self.isAddProductVariationsEnabled = featureFlagService.isFeatureFlagEnabled(.addProductVariations)
        configureSections(product: product, actionsFactory: actionsFactory)
    }
}

private extension DefaultProductFormTableViewModel {
    mutating func configureSections(product: ProductFormDataModel, actionsFactory: ProductFormActionsFactoryProtocol) {
        sections = [.primaryFields(rows: primaryFieldRows(product: product, actions: actionsFactory.primarySectionActions())),
                    .settings(rows: settingsRows(productModel: product, actions: actionsFactory.settingsSectionActions()))]
            .filter { $0.isNotEmpty }
    }

    func primaryFieldRows(product: ProductFormDataModel, actions: [ProductFormEditAction]) -> [ProductFormSection.PrimaryFieldRow] {
        return actions.map { action in
            switch action {
            case .images(let editable):
                return .images(isEditable: editable)
            case .name(let editable):
                return .name(name: product.name, isEditable: editable)
            case .variationName:
                return .variationName(name: product.name)
            case .description(let editable):
                return .description(description: product.trimmedFullDescription, isEditable: editable)
            default:
                fatalError("Unexpected action in the primary section: \(action)")
            }
        }
    }

    func settingsRows(productModel product: ProductFormDataModel, actions: [ProductFormEditAction]) -> [ProductFormSection.SettingsRow] {
        switch product {
        case let product as EditableProductModel:
            return settingsRows(product: product, actions: actions)
        case let product as EditableProductVariationModel:
            return settingsRows(productVariation: product, actions: actions)
        default:
            fatalError("Unexpected product form data model: \(type(of: product))")
        }
    }

    func settingsRows(product: EditableProductModel, actions: [ProductFormEditAction]) -> [ProductFormSection.SettingsRow] {
        return actions.compactMap { action in
            switch action {
            case .priceSettings(let editable):
                return .price(viewModel: priceSettingsRow(product: product, isEditable: editable), isEditable: editable)
            case .reviews:
                return .reviews(viewModel: reviewsRow(product: product), ratingCount: product.ratingCount, averageRating: product.averageRating)
            case .productType(let editable):
                return .productType(viewModel: productTypeRow(product: product, isEditable: editable), isEditable: editable)
            case .shippingSettings(let editable):
                return .shipping(viewModel: shippingSettingsRow(product: product, isEditable: editable), isEditable: editable)
            case .inventorySettings(let editable):
                return .inventory(viewModel: inventorySettingsRow(product: product, isEditable: editable), isEditable: editable)
            case .categories(let editable):
                return .categories(viewModel: categoriesRow(product: product.product, isEditable: editable), isEditable: editable)
            case .tags(let editable):
                return .tags(viewModel: tagsRow(product: product.product, isEditable: editable), isEditable: editable)
            case .shortDescription(let editable):
                return .shortDescription(viewModel: shortDescriptionRow(product: product.product, isEditable: editable), isEditable: editable)
            case .externalURL(let editable):
                return .externalURL(viewModel: externalURLRow(product: product.product, isEditable: editable), isEditable: editable)
            case .sku(let editable):
                return .sku(viewModel: skuRow(product: product.product, isEditable: editable), isEditable: editable)
            case .groupedProducts(let editable):
                return .groupedProducts(viewModel: groupedProductsRow(product: product.product, isEditable: editable), isEditable: editable)
            case .variations:
                return .variations(viewModel: variationsRow(product: product.product))
            case .downloadableFiles(let editable):
                return .downloadableFiles(viewModel: downloadsRow(product: product, isEditable: editable), isEditable: editable)
            case .linkedProducts(let editable):
                return .linkedProducts(viewModel: linkedProductsRow(product: product, isEditable: editable), isEditable: editable)
            default:
                assertionFailure("Unexpected action in the settings section: \(action)")
                return nil
            }
        }
    }

    func settingsRows(productVariation: EditableProductVariationModel, actions: [ProductFormEditAction]) -> [ProductFormSection.SettingsRow] {
        return actions.compactMap { action in
            switch action {
            case .priceSettings(let editable):
                return .price(viewModel: variationPriceSettingsRow(productVariation: productVariation, isEditable: editable), isEditable: editable)
            case .attributes(let editable):
                return .attributes(viewModel: variationAttributesRow(productVariation: productVariation, isEditable: editable), isEditable: editable)
            case .shippingSettings(let editable):
                return .shipping(viewModel: shippingSettingsRow(product: productVariation, isEditable: editable), isEditable: editable)
            case .inventorySettings(let editable):
                return .inventory(viewModel: inventorySettingsRow(product: productVariation, isEditable: editable), isEditable: editable)
            case .status(let editable):
                return .status(viewModel: variationStatusRow(productVariation: productVariation, isEditable: editable), isEditable: editable)
            case .noPriceWarning:
                return .noPriceWarning(viewModel: noPriceWarningRow())
            default:
                assertionFailure("Unexpected action in the settings section: \(action)")
                return nil
            }
        }
    }
}

private extension DefaultProductFormTableViewModel {
    func priceSettingsRow(product: ProductFormDataModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.priceImage

        var priceDetails = [String]()

        // Regular price and sale price are both available only when a sale price is set.
        if let regularPrice = product.regularPrice, regularPrice.isNotEmpty {
            let formattedRegularPrice = currencyFormatter.formatAmount(regularPrice, with: currency) ?? ""
            priceDetails.append(String.localizedStringWithFormat(Localization.regularPriceFormat, formattedRegularPrice))

            if let salePrice = product.salePrice, salePrice.isNotEmpty {
                let formattedSalePrice = currencyFormatter.formatAmount(salePrice, with: currency) ?? ""
                priceDetails.append(String.localizedStringWithFormat(Localization.salePriceFormat, formattedSalePrice))
            }

            if let dateOnSaleStart = product.dateOnSaleStart, let dateOnSaleEnd = product.dateOnSaleEnd {
                let dateIntervalFormatter = DateIntervalFormatter.mediumLengthLocalizedDateIntervalFormatter
                dateIntervalFormatter.timeZone = siteTimezone
                let formattedTimeRange = dateIntervalFormatter.string(from: dateOnSaleStart, to: dateOnSaleEnd)
                priceDetails.append(String.localizedStringWithFormat(Localization.saleDatesFormat, formattedTimeRange))
            }
            else if let dateOnSaleStart = product.dateOnSaleStart, product.dateOnSaleEnd == nil {
                let dateFormatter = DateFormatter.mediumLengthLocalizedDateFormatter
                dateFormatter.timeZone = siteTimezone
                let formattedDate = dateFormatter.string(from: dateOnSaleStart)
                priceDetails.append(String.localizedStringWithFormat(Localization.saleDateFormatFrom, formattedDate))
            }
            else if let dateOnSaleEnd = product.dateOnSaleEnd, product.dateOnSaleStart == nil {
                let dateFormatter = DateFormatter.mediumLengthLocalizedDateFormatter
                dateFormatter.timeZone = siteTimezone
                let formattedDate = dateFormatter.string(from: dateOnSaleEnd)
                priceDetails.append(String.localizedStringWithFormat(Localization.saleDateFormatTo, formattedDate))
            }
        }

        let title = priceDetails.isEmpty ? Localization.addPriceSettingsTitle: Localization.priceSettingsTitle
        let details = priceDetails.isEmpty ? nil: priceDetails.joined(separator: "\n")
        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isEditable)
    }

    func variationPriceSettingsRow(productVariation: EditableProductVariationModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let priceViewModel = priceSettingsRow(product: productVariation, isEditable: isEditable)
        let tintColor = productVariation.isEnabledAndMissingPrice ? UIColor.warning: nil
        return .init(icon: priceViewModel.icon,
                     title: priceViewModel.title,
                     details: priceViewModel.details,
                     tintColor: tintColor,
                     isActionable: priceViewModel.isActionable)
    }

    func reviewsRow(product: ProductFormDataModel) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.productReviewsImage
        let title = Localization.reviewsTitle
        var details = Localization.emptyReviews
        if product.ratingCount > 0 {
            details = " · "
        }
        if product.ratingCount == 1 {
            details += Localization.singularReviewFormat
        }
        else if product.ratingCount > 1 {
            details += String.localizedStringWithFormat(Localization.pluralReviewsFormat, product.ratingCount)
        }

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details)
    }

    func inventorySettingsRow(product: ProductFormDataModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.inventoryImage
        let title = Localization.inventorySettingsTitle

        var inventoryDetails = [String]()

        if let sku = product.sku, !sku.isEmpty {
            inventoryDetails.append(String.localizedStringWithFormat(Localization.skuFormat, sku))
        }

        if let stockQuantity = product.stockQuantity, product.manageStock {
            inventoryDetails.append(String.localizedStringWithFormat(Localization.stockQuantityFormat, stockQuantity))
        } else if product.manageStock == false && product.isStockStatusEnabled() {
            let stockStatus = product.stockStatus
            inventoryDetails.append(stockStatus.description)
        }

        let details = inventoryDetails.isEmpty ? nil: inventoryDetails.joined(separator: "\n")

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isEditable)
    }

    func productTypeRow(product: ProductFormDataModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.productImage
        let title = Localization.productTypeTitle

        let details: String
        switch product.productType {
        case .simple:
            switch (product.downloadable, product.virtual) {
            case (true, _):
                details = Localization.downloadableProductType
            case (false, true):
                details = Localization.virtualProductType
            case (false, false):
                details = Localization.physicalProductType
            }
        case .custom(let customProductType):
            // Custom product type description is the slug, thus we replace the dash with space and capitalize the string.
            details = customProductType.description.replacingOccurrences(of: "-", with: " ").capitalized
        default:
            details = product.productType.description
        }

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isEditable)
    }

    func shippingSettingsRow(product: ProductFormDataModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.shippingImage
        let title = Localization.shippingSettingsTitle

        var shippingDetails = [String]()

        // Weight[unit]
        if let weight = product.weight, let weightUnit = ServiceLocator.shippingSettingsService.weightUnit, !weight.isEmpty {
            shippingDetails.append(String.localizedStringWithFormat(Localization.weightFormat,
                                                                    weight, weightUnit))
        }

        // L x W x H[unit]
        let length = product.dimensions.length
        let width = product.dimensions.width
        let height = product.dimensions.height
        let dimensions = [length, width, height].filter({ !$0.isEmpty })
        if let dimensionUnit = ServiceLocator.shippingSettingsService.dimensionUnit,
            !dimensions.isEmpty {
            switch dimensions.count {
            case 1:
                let dimension = dimensions[0]
                shippingDetails.append(String.localizedStringWithFormat(Localization.oneDimensionFormat,
                                                                        dimension, dimensionUnit))
            case 2:
                let firstDimension = dimensions[0]
                let secondDimension = dimensions[1]
                shippingDetails.append(String.localizedStringWithFormat(Localization.twoDimensionsFormat,
                                                                        firstDimension, secondDimension, dimensionUnit))
            case 3:
                let firstDimension = dimensions[0]
                let secondDimension = dimensions[1]
                let thirdDimension = dimensions[2]
                shippingDetails.append(String.localizedStringWithFormat(Localization.fullDimensionsFormat,
                                                                        firstDimension, secondDimension, thirdDimension, dimensionUnit))
            default:
                break
            }
        }

        let details: String? = shippingDetails.isEmpty ? nil: shippingDetails.joined(separator: "\n")
        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isEditable)
    }

    func categoriesRow(product: Product, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.categoriesIcon
        let title = Localization.categoriesTitle
        let details = product.categoriesDescription() ?? Localization.categoriesPlaceholder
        return ProductFormSection.SettingsRow.ViewModel(icon: icon, title: title, details: details, isActionable: isEditable)
    }

    func tagsRow(product: Product, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.tagsIcon
        let title = Localization.tagsTitle
        let details = product.tagsDescription() ?? Localization.tagsPlaceholder
        return ProductFormSection.SettingsRow.ViewModel(icon: icon, title: title, details: details, isActionable: isEditable)
    }

    func shortDescriptionRow(product: Product, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.shortDescriptionImage
        let title = Localization.shortDescriptionTitle
        let details = product.trimmedShortDescription?.isNotEmpty == true ? product.trimmedShortDescription: Localization.shortDescriptionPlaceholder

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        numberOfLinesForDetails: 1,
                                                        isActionable: isEditable)
    }

    // MARK: Affiliate products only

    func externalURLRow(product: Product, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.linkImage
        let title = product.externalURL?.isNotEmpty == true ? Localization.externalURLTitle: Localization.addExternalURLTitle
        let details = product.externalURL

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        numberOfLinesForDetails: 1,
                                                        isActionable: isEditable)
    }

    func skuRow(product: Product, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.inventoryImage
        let title = Localization.skuTitle
        let details = product.sku

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        numberOfLinesForDetails: 1,
                                                        isActionable: isEditable)
    }

    // MARK: Grouped products only

    func groupedProductsRow(product: Product, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.widgetsImage
        let title = product.groupedProducts.isEmpty ? Localization.addGroupedProductsTitle: Localization.groupedProductsTitle
        let details: String

        switch product.groupedProducts.count {
        case 1:
            details = String.localizedStringWithFormat(Localization.singularGroupedProductFormat, product.groupedProducts.count)
        case 2...:
            details = String.localizedStringWithFormat(Localization.pluralGroupedProductsFormat, product.groupedProducts.count)
        default:
            details = ""
        }

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        numberOfLinesForDetails: 1,
                                                        isActionable: isEditable)
    }

    // MARK: Variable products only

    func variationsRow(product: Product) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.variationsImage
        let title = (product.variations.isEmpty && isAddProductVariationsEnabled) ? Localization.addVariationsTitle : Localization.variationsTitle

        let details: String
        let format = NSLocalizedString("%1$@ (%2$ld options)", comment: "Format for each Product attribute")

        switch product.variations.count {
        case 1...:
            details = product.attributes
                .map({ String.localizedStringWithFormat(format, $0.name, $0.options.count) })
                .joined(separator: "\n")
        default:
            if isAddProductVariationsEnabled {
                details = ""
            }
            else {
                details = Localization.variationsPlaceholder
            }
        }

        let isActionable = product.variations.isNotEmpty || (product.variations.isEmpty && isAddProductVariationsEnabled)

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isActionable)
    }

    // MARK: Product variation only

    func variationStatusRow(productVariation: EditableProductVariationModel, isEditable: Bool) -> ProductFormSection.SettingsRow.SwitchableViewModel {
        let icon = UIImage.visibilityImage
        let title = Localization.variationStatusTitle
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                                 title: title,
                                                                 details: nil,
                                                                 isActionable: false)
        let isSwitchOn = productVariation.isEnabled
        return ProductFormSection.SettingsRow.SwitchableViewModel(viewModel: viewModel, isSwitchOn: isSwitchOn, isActionable: isEditable)
    }

    func noPriceWarningRow() -> ProductFormSection.SettingsRow.WarningViewModel {
        let icon = UIImage.infoOutlineImage
        let title = Localization.noPriceWarningTitle
        return ProductFormSection.SettingsRow.WarningViewModel(icon: icon, title: title)
    }

    func variationAttributesRow(productVariation: EditableProductVariationModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.customizeImage
        let title = Localization.variationAttributesTitle
        let details = productVariation.name

        return .init(icon: icon, title: title, details: details, isActionable: isEditable)
    }

    // MARK: Product downloads only

    func downloadsRow(product: ProductFormDataModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.cloudImage
        let title = Localization.downloadsTitle
        var details = Localization.emptyDownloads

        switch product.downloadableFiles.count {
        case 1:
            details = String.localizedStringWithFormat(Localization.singularDownloadsFormat, product.downloadableFiles.count)
        case 2...:
            details = String.localizedStringWithFormat(Localization.pluralDownloadsFormat, product.downloadableFiles.count)
        default:
            details = Localization.emptyDownloads
        }

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isEditable)
    }

    // MARK: Linked products only

    func linkedProductsRow(product: ProductFormDataModel, isEditable: Bool) -> ProductFormSection.SettingsRow.ViewModel {
        let icon = UIImage.linkedProductsImage
        let title = Localization.linkedProductsTitle

        let details = [
            Localization.upsellProducts(count: product.upsellIDs.count),
            Localization.crossSellProducts(count: product.crossSellIDs.count),
        ].joined(separator: "\n")

        return ProductFormSection.SettingsRow.ViewModel(icon: icon,
                                                        title: title,
                                                        details: details,
                                                        isActionable: isEditable)
    }
}

private extension DefaultProductFormTableViewModel {
    enum Localization {
        static let addPriceSettingsTitle = NSLocalizedString("Add Price",
                                                             comment: "Title for adding the price settings row on Product main screen")
        static let priceSettingsTitle = NSLocalizedString("Price",
                                                          comment: "Title for editing the price settings row on Product main screen")
        static let reviewsTitle = NSLocalizedString("Reviews",
                                                    comment: "Title of the Reviews row on Product main screen")
        static let inventorySettingsTitle = NSLocalizedString("Inventory",
                                                              comment: "Title of the Inventory Settings row on Product main screen")
        static let productTypeTitle = NSLocalizedString("Product type",
                                                              comment: "Title of the Product Type row on Product main screen")
        static let shippingSettingsTitle = NSLocalizedString("Shipping",
                                                             comment: "Title of the Shipping Settings row on Product main screen")
        static let categoriesTitle = NSLocalizedString("Categories",
                                                       comment: "Title of the Categories row on Product main screen")
        static let tagsTitle = NSLocalizedString("Tags",
                                                 comment: "Title of the Tags row on Product main screen")
        static let shortDescriptionTitle = NSLocalizedString("Short description",
                                                             comment: "Title of the Short Description row on Product main screen")
        static let skuTitle = NSLocalizedString("SKU",
                                                comment: "Title of the SKU row on Product main screen")
        static let addExternalURLTitle =
            NSLocalizedString("Add product link",
                              comment: "Title for adding an external URL row on Product main screen for an external/affiliate product")
        static let externalURLTitle = NSLocalizedString("Product link",
                                                        comment: "Title of the external URL row on Product main screen for an external/affiliate product")
        static let addGroupedProductsTitle =
            NSLocalizedString("Add products to the group",
                              comment: "Title for adding grouped products row on Product main screen for a grouped product")
        static let groupedProductsTitle = NSLocalizedString("Grouped products",
                                                            comment: "Title for editing grouped products row on Product main screen for a grouped product")

        // Price
        static let regularPriceFormat = NSLocalizedString("Regular price: %@",
                                                          comment: "Format of the regular price on the Price Settings row")
        static let salePriceFormat = NSLocalizedString("Sale price: %@",
                                                       comment: "Format of the sale price on the Price Settings row")
        static let saleDatesFormat = NSLocalizedString("Sale dates: %@",
                                                       comment: "Format of the sale period on the Price Settings row")
        static let saleDateFormatFrom = NSLocalizedString("Sale dates: From %@",
                                                    comment: "Format of the sale period on the Price Settings row from a certain date")
        static let saleDateFormatTo = NSLocalizedString("Sale dates: Until %@",
                                                    comment: "Format of the sale period on the Price Settings row until a certain date")

        // Reviews
        static let emptyReviews = NSLocalizedString("No ratings",
                                                    comment: "Placeholder for empty product ratings")
        static let singularReviewFormat = NSLocalizedString("rated once",
                                                            comment: "Format of the number of product ratings in singular form")
        static let pluralReviewsFormat = NSLocalizedString("rated %ld times",
                                                           comment: "Format of the number of product ratings in plural form")

        // Inventory
        static let skuFormat = NSLocalizedString("SKU: %@",
                                                 comment: "Format of the SKU on the Inventory Settings row")
        static let stockQuantityFormat = NSLocalizedString("Quantity: %ld",
                                                           comment: "Format of the stock quantity on the Inventory Settings row")

        // Product Type
        static let downloadableProductType = NSLocalizedString("Downloadable",
                                                               comment: "Display label for simple downloadable product type.")
        static let virtualProductType = NSLocalizedString("Virtual",
                                                          comment: "Display label for simple virtual product type.")
        static let physicalProductType = NSLocalizedString("Physical",
                                                           comment: "Display label for simple physical product type.")

        // Shipping
        static let weightFormat = NSLocalizedString("Weight: %1$@%2$@",
                                                    comment: "Format of the weight on the Shipping Settings row - weight[unit]")
        static let oneDimensionFormat = NSLocalizedString("Dimensions: %1$@%2$@",
                                                          comment: "Format of one dimension on the Shipping Settings row - dimension[unit]")
        static let twoDimensionsFormat = NSLocalizedString("Dimensions: %1$@ x %2$@ %3$@",
                                                           comment: "Format of 2 dimensions on the Shipping Settings row - dimension x dimension[unit]")
        static let fullDimensionsFormat = NSLocalizedString("Dimensions: %1$@ x %2$@ x %3$@ %4$@",
                                                            comment: "Format of all 3 dimensions on the Shipping Settings row - L x W x H[unit]")

        // Short description
        static let shortDescriptionPlaceholder = NSLocalizedString("A brief excerpt about the product",
                                                                   comment: "Placeholder of the Product Short Description row on Product main screen")

        // Categories
        static let categoriesPlaceholder = NSLocalizedString("Uncategorized",
                                                             comment: "Placeholder of the Product Categories row on Product main screen")
        // Tags
        static let tagsPlaceholder = NSLocalizedString("No tags",
                                                       comment: "Placeholder of the Product Tags row on Product main screen")

        // Grouped products
        static let singularGroupedProductFormat = NSLocalizedString("%ld product",
                                                                    comment: "Format of the number of grouped products in singular form")
        static let pluralGroupedProductsFormat = NSLocalizedString("%ld products",
                                                                   comment: "Format of the number of grouped products in plural form")

        // Variations
        static let addVariationsTitle = NSLocalizedString("Add variations",
                                                          comment: "Title for adding variations row on Product main screen for a variable product")
        static let variationsTitle =
            NSLocalizedString("Variations",
                              comment: "Title of the Product Variations row on Product main screen for a variable product")
        static let variationsPlaceholder = NSLocalizedString("No variations yet",
                                                             comment: "Placeholder of the Product Variations row on Product main screen for a variable product")

        // Variation status
        static let variationStatusTitle =
            NSLocalizedString("Enabled",
                              comment: "Title of the status row on Product Variation main screen to enable/disable a variation")

        // Variation attributes
        static let variationAttributesTitle = NSLocalizedString("Attributes", comment: "Title of the attributes row on Product Variation main screen")

        // No price warning row
        static let noPriceWarningTitle =
            NSLocalizedString("Variations without price won’t be shown in your store",
                              comment: "Title of the no price warning row on Product Variation main screen when a variation is enabled without a price")

        // Downloadable files
        static let downloadsTitle =
            NSLocalizedString("Downloadable files",
                              comment: "Title of the Downloadable Files row on Product main screen")

        static let emptyDownloads = NSLocalizedString("No files yet",
                                                      comment: "Placeholder for empty Downloadable Files row on Product main screen")
        static let singularDownloadsFormat = NSLocalizedString("%ld file",
                                                               comment: "Format of the number of Downloadable Files row in the singular form. Reads, `1 file`")
        static let pluralDownloadsFormat = NSLocalizedString("%ld files",
                                                           comment: "Format of the number of Downloadable Files row in the plural form. Reads, `5 files`")

        // Linked Products
        static let linkedProductsTitle = NSLocalizedString("Linked products",
                                                           comment: "Title of the Linked Products row on Product main screen")
        static func upsellProducts(count: Int) -> String {
            let format: String = {
                if count <= 1 {
                    return NSLocalizedString("%ld upsell product",
                                             comment: "Format of upsell linked products row in the singular form. Reads, `1 upsell product`")
                } else {
                    return NSLocalizedString("%ld upsell products",
                                             comment: "Format of upsell linked products row in the plural form. Reads, `5 upsell products`")
                }
            }()

            return String.localizedStringWithFormat(format, count)
        }
        static func crossSellProducts(count: Int) -> String {
            let format: String = {
                if count <= 1 {
                    return NSLocalizedString("%ld cross-sell product",
                                             comment: "Format of cross-sell linked products row in the singular form. Reads, `1 cross-sell product`")
                } else {
                    return NSLocalizedString("%ld cross-sell products",
                                             comment: "Format of cross-sell linked products row in the plural form. Reads, `5 cross-sell products`")
                }
            }()

            return String.localizedStringWithFormat(format, count)
        }
    }
}
