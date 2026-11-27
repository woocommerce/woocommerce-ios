import StoreDesignSystem
import SwiftUI
import Yosemite

struct StoreProductFormScreen: View {
    let store: StoreProductFormRendererStore
    @FocusState private var isNameFocused: Bool
    @State private var isShowingMoreDetails = false
    @State private var selectedDetail: ProductFormBottomSheetAction?
    @State private var isAIButtonVisible = false
    @State private var isShowingAITooltip = false
    @State private var didShowAITooltip = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: StoreSpacing.s0) {
                ForEach(store.primaryRows) { item in
                    primaryRow(item.row)
                    switch item.row {
                    case .description(_, _, true), .descriptionAI: EmptyView()
                    default: StoreDivider()
                    }
                }
                if !store.primaryRows.isEmpty && !store.settingsRows.isEmpty {
                    Color.storeSurface.frame(height: StoreSpacing.s3)
                    StoreDivider()
                }
                ForEach(store.settingsRows) { item in
                    settingsRow(item)
                }
                if !store.settingsRows.isEmpty {
                    StoreDivider()
                }
            }
        }
        .accessibilityIdentifier("product-form")
        .scrollDismissesKeyboard(.interactively)
        .background(Color.storeSurface)
        .safeAreaInset(edge: .bottom, spacing: StoreSpacing.s0) {
            if !store.moreDetailsActions.isEmpty {
                StoreCell(Localization.addMoreDetails,
                          showsDisclosureIndicator: true,
                          action: showMoreDetails,
                          leading: StoreIcon.Plus.regular.image(size: .largeIncreased)
                            .foregroundStyle(Color.storePrimary)
                            .accessibilityHidden(true))
                    .compositingGroup()
                    .shadow(radius: StoreSpacing.s2, y: -StoreSpacing.s1)
            }
        }
        .storeSheet(isPresented: $isShowingMoreDetails, onDismiss: openSelectedDetail) {
            Text(Localization.addMoreDetails)
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(Color.storeOnSurface)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, StorePadding.p7)
                .padding(.vertical, StorePadding.p4)
            ForEach(store.moreDetailsActions, id: \.self) { action in
                let selectDetail = {
                    selectedDetail = action
                    isShowingMoreDetails = false
                }
                StoreCell(action.title,
                          description: action.subtitle,
                          configuration: .init(density: .compact),
                          showsDisclosureIndicator: true,
                          action: selectDetail)
            }
        }
    }

    private func showMoreDetails() {
        isNameFocused = false
        isShowingAITooltip = false
        isShowingMoreDetails = true
    }

    private func openSelectedDetail() {
        guard let action = selectedDetail else { return }
        selectedDetail = nil
        store.onMoreDetailsSelected(action)
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
                            .padding(.vertical, StorePadding.p5)
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
        case .name(_, let isEditable, let status):
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                if isEditable && status != .published {
                    StoreBadge(status == .privateStatus ? LabeledTextViewTableViewCell.privateStatusTitle : status.description,
                               tone: status == .pending ? .warning : .neutral)
                        .padding(.horizontal, StorePadding.p7)
                        .padding(.top, StorePadding.p4)
                }
                productName(isEditable: isEditable)
            }
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
        case .linkedProductsPromo(let viewModel):
            StoreDashboardFeatureAnnouncementCard(viewModel: viewModel) {
                store.onInlineAction(.reloadLinkedProductsPromo)
            } callToAction: {
                store.onInlineAction(.openLinkedProducts)
            }
            .padding(StorePadding.p4)
            .accessibilityIdentifier("product-linked-products-promo-cell")
        case .descriptionAI:
            descriptionAIButton
        case .learnMoreAboutAI:
            aiLegalText
        case .promoteWithBlaze:
            let iconSize = ProductFormTableViewDataSource.blazeButtonIconSize
            StoreCell(Localization.promoteWithBlaze,
                      configuration: .init(density: .compact, iconTint: .title),
                      showsDisclosureIndicator: true,
                      action: { store.onPrimaryRowSelected(row) },
                      leading: Image(uiImage: .blaze)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize.width, height: iconSize.height)
                        .accessibilityHidden(true))
                .accessibilityHint(Localization.promoteWithBlazeAccessibilityHint)
        case .separator:
            EmptyView()
        }
    }

    private var descriptionAIButton: some View {
        StoreButton(Localization.writeWithAI, icon: StoreIcon.Sparkles.regular, variant: .tonal) {
            isShowingAITooltip = false
            store.onInlineAction(.descriptionAI)
        }
        .accessibilityIdentifier("product-description-ai")
        .storeTooltip(isPresented: $isShowingAITooltip,
                      preferredPlacement: .below,
                      title: ProductFormAITooltipLocalization.title,
                      message: ProductFormAITooltipLocalization.message,
                      onDismiss: store.onAITooltipDismissed)
        .onScrollVisibilityChange(threshold: 0.99) { isAIButtonVisible = $0 }
        .onChange(of: isAIButtonVisible && store.canShowAITooltip) { _, canShowTooltip in
            if !canShowTooltip {
                isShowingAITooltip = false
            } else if !didShowAITooltip {
                isShowingAITooltip = true
                didShowAITooltip = true
                store.onAITooltipShown()
            }
        }
        .padding(.horizontal, StorePadding.p7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.storeSurfaceBright)
    }

    private var aiLegalText: some View {
        var text = AttributedString(String.localizedStringWithFormat(Localization.legalText, Localization.learnMore))
        if let linkRange = text.range(of: Localization.learnMore) {
            text[linkRange].link = ProductFormTableViewDataSource.legalURL
        }
        return Text(text)
            .storeTextStyle(.bodySmall)
            .foregroundStyle(Color.storeOnSurfaceVariant)
            .tint(Color.storePrimary)
            .environment(\.openURL, OpenURLAction { url in
                store.onInlineAction(.openAILegalPage(url))
                return .handled
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, StorePadding.p7)
            .padding(.vertical, StorePadding.p4)
            .background(Color.storeSurfaceBright)
    }

    private func productName(isEditable: Bool) -> some View {
        Group {
            if isEditable {
                TextField(Localization.namePlaceholder,
                          text: productNameInput,
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

    private var productNameInput: Binding<String> {
        Binding(get: { store.productName }, set: { name in
            // A vertical TextField can deliver Return as a newline through its binding.
            if name.contains(where: \.isNewline) {
                let insertions = name.difference(from: store.productName).insertions
                if insertions.count == 1, case .insert(_, let character, _) = insertions[0], character.isNewline {
                    isNameFocused = false
                    return
                }
            }
            store.productName = name
        })
    }

    private func readOnlyName(_ name: String) -> some View {
        Text(name).accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func settingsRow(_ item: StoreProductFormSettingsRow) -> some View {
        switch item.row {
        case .status(let model, let isEditable):
            let title = model.viewModel.title ?? ""
            StoreCell(title,
                      description: model.viewModel.details,
                      configuration: .init(density: .compact, iconTint: .title),
                      leading: item.icon.image(size: .largeIncreased).accessibilityHidden(true)) {
                Toggle(title, isOn: Binding(get: { model.isSwitchOn }, set: { store.onInlineAction(.statusChanged($0)) }))
                    .labelsHidden()
                    .tint(Color.storePrimary)
                    .disabled(!isEditable || !model.isActionable)
                    .accessibilityIdentifier(item.accessibilityIdentifier)
            }
        case .noPriceWarning, .noVariationsWarning:
            StoreNoticeBanner(item.viewModel.title ?? "",
                              tone: .warning,
                              icon: item.icon,
                              actionTitle: item.isActionable ? DefaultProductFormTableViewModel.Localization.variationsTitle : nil,
                              action: item.isActionable ? { store.onSettingsRowSelected(item.row) } : nil)
                .padding(StorePadding.p4)
                .accessibilityIdentifier(item.accessibilityIdentifier)
        default:
            settingsCell(item)
        }
    }

    private func settingsCell(_ item: StoreProductFormSettingsRow) -> some View {
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
            if !model.hideSeparator && item.id != store.settingsRows.last?.id {
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
