import Observation
import Yosemite

/// The host supplies current form sections and forwards actions to the existing product form router.
@MainActor
@Observable
final class StoreProductFormRendererStore {
    private(set) var primaryRows: [PrimaryRow] = []
    private(set) var settingsRows: [StoreProductFormSettingsRow] = []
    private(set) var imageStatuses: [ProductImageStatus] = []
    private(set) var moreDetailsActions: [ProductFormBottomSheetAction] = []
    private(set) var canShowAITooltip = false

    private var name = ""
    var productName: String {
        get { name }
        set {
            guard name != newValue else { return }
            name = newValue
            onInlineAction(.nameChanged(newValue))
        }
    }

    let imageLoader: ProductUIImageLoader
    let onPrimaryRowSelected: (ProductFormSection.PrimaryFieldRow) -> Void
    let onSettingsRowSelected: (ProductFormSection.SettingsRow) -> Void
    let onInlineAction: (ProductFormInlineAction) -> Void
    var onMoreDetailsSelected: (ProductFormBottomSheetAction) -> Void = { _ in }
    var onAITooltipShown: () -> Void = {}
    var onAITooltipDismissed: () -> Void = {}

    init(sections: [ProductFormSection],
         imageStatuses: [ProductImageStatus],
         imageLoader: ProductUIImageLoader,
         onPrimaryRowSelected: @escaping (ProductFormSection.PrimaryFieldRow) -> Void,
         onSettingsRowSelected: @escaping (ProductFormSection.SettingsRow) -> Void,
         onInlineAction: @escaping (ProductFormInlineAction) -> Void) {
        self.imageLoader = imageLoader
        self.onPrimaryRowSelected = onPrimaryRowSelected
        self.onSettingsRowSelected = onSettingsRowSelected
        self.onInlineAction = onInlineAction
        update(sections: sections)
        updateImageStatuses(imageStatuses)
    }

    func update(sections: [ProductFormSection]) {
        var primaryRows: [PrimaryRow] = []
        var settingsRows: [StoreProductFormSettingsRow] = []
        for section in sections {
            switch section {
            case .primaryFields(let rows):
                primaryRows.append(contentsOf: rows.compactMap(PrimaryRow.init))
            case .settings(let rows):
                settingsRows.append(contentsOf: rows.map(StoreProductFormSettingsRow.init))
            }
        }
        self.primaryRows = primaryRows
        self.settingsRows = settingsRows

        for item in primaryRows {
            if case .name(let name, _, _) = item.row {
                updateProductName(name ?? "")
                break
            }
        }
    }

    func updateProductName(_ name: String) {
        if self.name != name {
            self.name = name
        }
    }

    func updateImageStatuses(_ statuses: [ProductImageStatus]) {
        imageStatuses = statuses
    }

    func updateMoreDetailsActions(_ actions: [ProductFormBottomSheetAction]) {
        moreDetailsActions = actions
    }

    func updateAITooltipEligibility(_ isEligible: Bool) {
        canShowAITooltip = isEligible
    }

    struct PrimaryRow: Identifiable {
        enum ID {
            case images, name, variationName, description, linkedProductsPromo, descriptionAI, learnMoreAboutAI, promoteWithBlaze
        }

        let id: ID
        let row: ProductFormSection.PrimaryFieldRow

        init?(_ row: ProductFormSection.PrimaryFieldRow) {
            self.row = row
            switch row {
            case .images: id = .images
            case .name: id = .name
            case .variationName: id = .variationName
            case .description: id = .description
            case .linkedProductsPromo: id = .linkedProductsPromo
            case .descriptionAI: id = .descriptionAI
            case .learnMoreAboutAI: id = .learnMoreAboutAI
            case .promoteWithBlaze: id = .promoteWithBlaze
            case .separator: return nil
            }
        }
    }
}
