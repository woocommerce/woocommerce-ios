import StoreDesignSystem
import SwiftUI

struct StoreProductFormScreen<PinnedContent: View>: View {
    @Bindable private var store: StoreProductFormRendererStore
    @FocusState private var isNameFocused: Bool
    private let pinnedContent: PinnedContent

    init(store: StoreProductFormRendererStore, @ViewBuilder pinnedContent: () -> PinnedContent = { EmptyView() }) {
        self.store = store
        self.pinnedContent = pinnedContent()
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: StoreSpacing.s0) {
                ForEach(store.primaryRows) { item in
                    primaryRow(item.row)
                    StoreDivider()
                }
                if !store.primaryRows.isEmpty && !store.settingsRows.isEmpty {
                    Color.storeSurface.frame(height: StoreSpacing.s3)
                    StoreDivider()
                }
                ForEach(store.settingsRows) { item in
                    settingsRow(item)
                }
                StoreDivider()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.storeSurface)
        .safeAreaInset(edge: .bottom, spacing: StoreSpacing.s0) {
            pinnedContent
        }
    }

    @ViewBuilder
    private func primaryRow(_ row: ProductFormSection.PrimaryFieldRow) -> some View {
        switch row {
        case .images(let isEditable, let isStorePublic, let allowsMultiple, let isVariation):
            if !isStorePublic || isEditable || !store.imageStatuses.isEmpty {
                VStack(spacing: StoreSpacing.s0) {
                    if isStorePublic {
                        StoreProductFormImageGallery(statuses: store.imageStatuses,
                                                     isEditable: isEditable,
                                                     allowsMultiple: allowsMultiple,
                                                     isVariation: isVariation,
                                                     imageLoader: store.imageLoader,
                                                     onAction: store.onInlineAction)
                            .accessibilityLabel(Localization.imagesAccessibilityLabel)
                            .padding(.horizontal, StorePadding.p7)
                            .padding(.top, StorePadding.p5)
                    } else {
                        Button {
                            store.onPrimaryRowSelected(row)
                        } label: {
                            StoreNoticeBanner(Localization.wpComStoreNotPublicTitle,
                                              description: Localization.wpComStoreNotPublicText,
                                              tone: .warning,
                                              icon: StoreIcon.CircleInfo.regular)
                        }
                        .buttonStyle(.plain)
                        .padding(StorePadding.p4)
                    }
                }
                .background(Color.storeSurfaceBright)
            }
        case .name(_, let isEditable, _):
            productName(isEditable: isEditable)
                .background(Color.storeSurfaceBright)
        case .variationName(let name):
            readOnlyName(name)
                .modifier(NameStyle())
                .background(Color.storeSurfaceBright)
        case .description(let description, let isEditable, _):
            let hasDescription = description?.isEmpty == false
            let action: (() -> Void)? = isEditable ? { store.onPrimaryRowSelected(row) } : nil
            StoreCell(hasDescription ? Localization.descriptionTitle : Localization.descriptionPlaceholder,
                      description: hasDescription ? description : nil,
                      configuration: .init(density: .compact, iconTint: .title, descriptionLineLimit: 1),
                      showsDisclosureIndicator: isEditable,
                      action: action)
                .accessibilityHint(isEditable && hasDescription ? Localization.Accessibility.descriptionHint : "")
                .accessibilityIdentifier("product-description")
                .background(Color.storeSurfaceBright)
        case .linkedProductsPromo, .descriptionAI, .learnMoreAboutAI, .promoteWithBlaze, .separator:
            EmptyView()
        }
    }

    private func productName(isEditable: Bool) -> some View {
        Group {
            if isEditable {
                TextField(Localization.namePlaceholder,
                          text: $store.productName,
                          prompt: Text(Localization.namePlaceholder).foregroundStyle(Color.storeOnSurfaceVariant),
                          axis: .vertical)
                    .tint(Color.storePrimary)
                    .accessibilityLabel(Localization.nameAccessibilityLabel)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit { isNameFocused = false }
            } else {
                readOnlyName(store.productName)
            }
        }
        .modifier(NameStyle())
        .accessibilityIdentifier("product-title")
    }

    private func readOnlyName(_ name: String) -> some View {
        Text(name).accessibilityAddTraits(.isHeader)
    }

    private func settingsRow(_ item: StoreProductFormSettingsRow) -> some View {
        let model = item.viewModel
        let action: (() -> Void)? = item.isActionable ? { store.onSettingsRowSelected(item.row) } : nil
        let descriptionLineLimit = model.numberOfLinesForDetails > 0 ? model.numberOfLinesForDetails : nil
        return VStack(spacing: StoreSpacing.s0) {
            StoreCell(model.title ?? "",
                      description: item.review == nil ? model.details : nil,
                      configuration: .init(density: .compact, iconTint: .title, descriptionLineLimit: descriptionLineLimit),
                      showsDisclosureIndicator: item.isActionable,
                      action: action,
                      leading: item.icon.image(size: .largeIncreased).accessibilityHidden(true),
                      supportingContent: item.review.map { StoreProductFormReviewSummary(review: $0) })
                .accessibilityIdentifier(item.accessibilityIdentifier)
            if !model.hideSeparator && (item.review == nil || item.id != store.settingsRows.last?.id) {
                StoreDivider()
                    .padding(.leading, StoreSpacing.s12)
            }
        }
        .background(Color.storeSurfaceBright)
    }

    private typealias Localization = ProductFormTableViewDataSource.Localization

    private struct NameStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .storeTextStyle(.titleLarge)
                .foregroundStyle(Color.storeOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, StorePadding.p7)
                .padding(.vertical, StorePadding.p3)
                .frame(minHeight: StoreSize.formTitleRowHeight)
        }
    }
}
