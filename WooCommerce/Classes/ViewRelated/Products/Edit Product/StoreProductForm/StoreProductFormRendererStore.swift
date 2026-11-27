import Observation
import Yosemite

/// The host supplies current form sections and forwards actions to the existing product form router.
@MainActor
@Observable
final class StoreProductFormRendererStore {
    private(set) var primaryRows: [PrimaryRow] = []
    private(set) var settingsRows: [StoreProductFormSettingsRow] = []
    private(set) var imageStatuses: [ProductImageStatus] = []

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
                settingsRows.append(contentsOf: rows.compactMap(StoreProductFormSettingsRow.init))
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
        self.name = name
    }

    func updateImageStatuses(_ statuses: [ProductImageStatus]) {
        imageStatuses = statuses
    }

    struct PrimaryRow: Identifiable {
        enum ID {
            case images, name, variationName, description
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
            // The screen spaces sections directly. Promo and AI content follow in the next rollout.
            case .separator, .linkedProductsPromo, .descriptionAI, .learnMoreAboutAI, .promoteWithBlaze: return nil
            }
        }
    }
}
