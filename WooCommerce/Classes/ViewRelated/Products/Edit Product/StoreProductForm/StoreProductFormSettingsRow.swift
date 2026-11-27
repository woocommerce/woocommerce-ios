import StoreDesignSystem

struct StoreProductFormSettingsRow: Identifiable {
    typealias Row = ProductFormSection.SettingsRow

    let id: String
    let row: Row
    let viewModel: Row.ViewModel
    let review: Review?
    let accessibilityIdentifier: String

    struct Review {
        let average: Double?
        let countDescription: String
    }

    var icon: StoreIconImage {
        if case .quantityRules = row { return StoreIcon.Sliders.regular }
        return viewModel.icon.storeIcon
    }

    var isActionable: Bool {
        // The legacy Add-ons cell always shows a chevron, while its router checks editability.
        if case .addOns(_, let isEditable) = row { return isEditable }
        return viewModel.isActionable
    }

    init(_ row: Row) {
        switch row {
        case .price(let model, _): self.init("price", row, model)
        case .customFields(let model): self.init("custom-fields", row, model)
        case .reviews(let model, let count, let average):
            let rating = Double(average)
            let review = Review(average: count > 0 && rating?.isFinite == true ? rating : nil,
                                countDescription: DefaultProductFormTableViewModel.Localization.reviewCountDescription(count))
            self.init("reviews", row, model, review: review, accessibilityIdentifier: "product-review-cell")
        case .productType(let model, _): self.init("type", row, model)
        case .shipping(let model, _): self.init("shipping", row, model)
        case .inventory(let model, _): self.init("inventory", row, model)
        case .addOns(let model, _): self.init("add-ons", row, model)
        case .categories(let model, _): self.init("categories", row, model)
        case .tags(let model, _): self.init("tags", row, model)
        case .shortDescription(let model, _): self.init("short-description", row, model)
        case .externalURL(let model, _): self.init("external-url", row, model)
        case .simplifiedInventory(let model, _): self.init("simplified-inventory", row, model, accessibilityIdentifier: "product-inventory-cell")
        case .groupedProducts(let model, _): self.init("grouped-products", row, model)
        case .variations(let model): self.init("variations", row, model)
        case .downloadableFiles(let model, _): self.init("downloadable-files", row, model)
        case .linkedProducts(let model, _): self.init("linked-products", row, model)
        case .attributes(let model, _): self.init("attributes", row, model)
        case .bundledProducts(let model, _): self.init("bundled-products", row, model)
        case .components(let model, _): self.init("components", row, model)
        case .subscriptionFreeTrial(let model, _): self.init("subscription-free-trial", row, model)
        case .subscriptionExpiry(let model, _): self.init("subscription-expiry", row, model)
        case .quantityRules(let model): self.init("quantity-rules", row, model)
        case .status(let model, _): self.init("status", row, model.viewModel)
        case .noPriceWarning(let model): self.init("no-price-warning", row, warning: model)
        case .noVariationsWarning(let model): self.init("no-variations-warning", row, warning: model)
        }
    }

    private init(_ id: String, _ row: Row, warning: Row.WarningViewModel) {
        self.init(id, row, .init(icon: warning.icon, title: warning.title, details: nil, isActionable: warning.isActionable))
    }

    private init(_ id: String, _ row: Row, _ viewModel: Row.ViewModel, review: Review? = nil, accessibilityIdentifier: String? = nil) {
        self.id = id
        self.row = row
        self.viewModel = viewModel
        self.review = review
        self.accessibilityIdentifier = accessibilityIdentifier ?? "product-\(id)-cell"
    }
}

extension ProductFormSection.SettingsRow.Icon {
    var storeIcon: StoreIconImage {
        switch self {
        case .add: StoreIcon.CirclePlus.regular
        case .calendarClock: StoreIcon.CalendarXmark.regular
        case .categories: StoreIcon.Folder.regular
        case .cloud: StoreIcon.Cloud.regular
        case .customFields: StoreIcon.GridPlus.regular
        case .customize: StoreIcon.ScrewdriverWrench.regular
        case .hourglass: StoreIcon.Hourglass.regular
        case .information: StoreIcon.CircleInfo.regular
        case .inventory: StoreIcon.ListCheck.regular
        case .link: StoreIcon.UpRightFromSquare.regular
        case .linkedProducts: StoreIcon.Retweet.regular
        case .price: StoreIcon.SquareDollar.regular
        case .product: StoreIcon.Box.regular
        case .reviews: StoreIcon.Star.regular
        case .shipping: StoreIcon.Truck.regular
        case .shortDescription: StoreIcon.AlignLeft.regular
        case .tags: StoreIcon.Tag.regular
        case .variations: StoreIcon.Shapes.regular
        case .visibility: StoreIcon.Shield.regular
        case .widgets: StoreIcon.LayerGroup.regular
        }
    }
}
