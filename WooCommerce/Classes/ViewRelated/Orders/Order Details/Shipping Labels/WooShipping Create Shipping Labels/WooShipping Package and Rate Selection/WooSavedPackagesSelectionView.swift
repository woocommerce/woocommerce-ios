import SwiftUI

enum WooShippingPackageSource {
    case custom
    case predefined(sourceTitle: String, sourceID: String)

    var userFriendlyDescription: String {
        switch self {
        case .custom:
            return NSLocalizedString("Custom Package", comment: "Label used to mark a custom package in list of saved packages")
        case .predefined(let sourceTitle, _):
            return sourceTitle
        }
    }

    var sourceID: String? {
        guard case .predefined(_, let sourceID) = self else {
            return nil
        }
        return sourceID
    }

    var isCustomPackage: Bool {
        switch self {
        case .custom: true
        case .predefined: false
        }
    }
}

protocol WooShippingPackageDataRepresentable {
    // backend
    var id: String { get }
    var name: String { get }
    var length: String { get }
    var width: String { get }
    var height: String { get }
    var weight: String { get }
    // local
    var source: WooShippingPackageSource { get } // custom, predefined
    var packageType: String { get } // box, envelope
}

struct WooShippingPackageData: WooShippingPackageDataRepresentable {
    // backend
    let id: String
    let name: String
    let length: String
    let width: String
    let height: String
    let weight: String
    // local
    let source: WooShippingPackageSource
    let packageType: String

    init(id: String,
         name: String,
         length: String,
         width: String,
         height: String,
         weight: String,
         source: WooShippingPackageSource,
         packageType: String) {
        self.id = id
        self.name = name
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight

        self.source = source
        self.packageType = packageType
    }

    init(name: String,
         length: String,
         width: String,
         height: String,
         weight: String,
         source: WooShippingPackageSource,
         packageType: String) {
        self.init(id: name,
                  name: name,
                  length: length,
                  width: width,
                  height: height,
                  weight: weight,
                  source: source,
                  packageType: packageType)
    }

    static func from(_ result: ParcelFittingResult,
                      carriers: [ParcelPresetCarrier]) -> WooShippingPackageData {
        switch result {
        case .carrierPackage(let package, _):
            let carrier = carriers.first { $0.packages.contains { $0.id == package.id } }
            let source: WooShippingPackageSource = carrier.map {
                .predefined(sourceTitle: $0.name, sourceID: $0.id)
            } ?? .custom
            return WooShippingPackageData(
                id: package.id,
                name: package.name,
                length: ParcelDimensions.formatValue(package.length),
                width: ParcelDimensions.formatValue(package.width),
                height: ParcelDimensions.formatValue(package.height),
                weight: "",
                source: source,
                packageType: "box"
            )
        case .customDimensions(let dims):
            return WooShippingPackageData(
                id: "custom_box",
                name: "",
                length: ParcelDimensions.formatValue(dims.length),
                width: ParcelDimensions.formatValue(dims.width),
                height: ParcelDimensions.formatValue(dims.height),
                weight: "",
                source: .custom,
                packageType: "box"
            )
        }
    }
}

extension WooShippingPackageDataRepresentable {
    func dimensionsDescription(unit: String) -> String {
        guard height.isNotEmpty, let numericHeight = Int(height), numericHeight > 0 else {
            return "\(length) x \(width) \( unit)"
        }
        return "\(length) x \(width) x \(height) \( unit)"
    }

    func weightDescription(unit: String) -> String? {
        guard weight.isNotEmpty else {
            return nil
        }
        return "\(weight) \(unit)"
    }

    var displayName: String {
        name.isNotEmpty ? name : source.userFriendlyDescription
    }
}

struct WooSavedPackagesSelectionView: View {
    @ObservedObject private var viewModel: WooShippingAddPackageViewModel
    private let addPackageAction: (WooShippingPackageDataRepresentable) -> Void
    private let addingCustomPackageHandler: () -> Void

    init(viewModel: WooShippingAddPackageViewModel,
         addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void,
         addingCustomPackageHandler: @escaping () -> Void) {
        self.viewModel = viewModel
        self.addPackageAction = addPackageAction
        self.addingCustomPackageHandler = addingCustomPackageHandler
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasSavedPackages {
                Divider()
                ScrollViewReader { scroll in
                    List {
                        packagesSection(for: viewModel.customSavedPackages)
                        packagesSection(for: viewModel.predefinedSavedPackages)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadPackages()
                    }
                    .task {
                        scroll.scrollTo(viewModel.selectedSavedPackageId)
                    }
                }
                Divider()
            } else if viewModel.isLoadingPackages {
                // Loading state
                loadingStateView
            } else if viewModel.packageLoadingError != nil {
                // Error state
                loadingPackagesErrorView
            } else {
                // No packages loaded
                emptyStateView
            }

            Spacer()
            Button(selectionButtonText) {
                addPackageButtonTapped()
            }
            .disabled(selectionButtonDisabled)
            .renderedIf(viewModel.hasSavedPackages)
            .if(viewModel.previousSelectedAndSelectedSavedPackageAreSame) {
                $0.buttonStyle(SecondaryButtonStyle())
            }
            .if(!viewModel.previousSelectedAndSelectedSavedPackageAreSame) {
                $0.buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
    }
}

private extension WooSavedPackagesSelectionView {
    var loadingStateView: some View {
        VStack {
            Spacer()
            ProgressView().progressViewStyle(.circular)
            Spacer()
        }
    }

    var loadingPackagesErrorView: some View {
        VStack(spacing: Layout.contentSpacing) {
            Spacer()
            Image(uiImage: .grayErrorIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.errorIconSize, height: Layout.errorIconSize)
            Text(Localization.loadingPackageError)
                .multilineTextAlignment(.center)
            Button(Localization.retryCTA) {
                Task {
                    await viewModel.loadPackages()
                }
            }
            Spacer()
        }
    }

    var emptyStateView: some View {
        VStack(spacing: Layout.contentSpacing) {
            Spacer()
            Image(uiImage: .giftIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.errorIconSize, height: Layout.errorIconSize)
            Text(Localization.emptyStateMessage)
                .multilineTextAlignment(.center)
                .bold()
                .fixedSize(horizontal: false, vertical: true)
            Button(Localization.createCustomPackageCTA) {
                addingCustomPackageHandler()
            }
            .buttonStyle(PrimaryButtonStyle())
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Layout.ctaPadding)
            Spacer()
        }
        .scrollVerticallyIfNeeded()
    }

    var selectionButtonDisabled: Bool {
        viewModel.selectedSavedPackageId == nil || !viewModel.hasSavedPackages
    }

    var selectionButtonText: String {
        if selectionButtonDisabled {
            return WooShippingAddPackageView.Localization.selectPackage
        }
        if let previousSelectedPackage = viewModel.previousSelectedPackage {
            if previousSelectedPackage.id == viewModel.selectedSavedPackageId {
                return WooShippingAddPackageView.Localization.done
            }
            return WooShippingAddPackageView.Localization.useSelectedPackage
        }
        return WooShippingAddPackageView.Localization.addPackage
    }

    @ViewBuilder
    func packagesSection(for packages: [any WooShippingPackageDataRepresentable]) -> some View {
        if packages.isEmpty {
            EmptyView()
        }
        else {
            Section {
                packagesRows(for: packages)
            }
            .listRowInsets(.zero)
        }
    }

    func packagesRows(for packages: [any WooShippingPackageDataRepresentable]) -> some View {
        ForEach(packages, id: \.id) { package in
            WooShippingPackageOptionView(
                isSelected: viewModel.selectedSavedPackageId == package.id,
                package: package,
                showTopDivider: false,
                showSource: true,
                tapAction: {
                    viewModel.selectedSavedPackageId = viewModel.selectedSavedPackageId == package.id ? nil : package.id
                }
            )
            .id(package.id)
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                return 16
            }
            .swipeActions {
                Button {
                    withAnimation {
                        viewModel.removeSavedPackage(package)
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .tint(Color.withColorStudio(name: .red, shade: .shade50))
            }
        }
        .listRowInsets(.zero)
    }

    func addPackageButtonTapped() {
        // call addPackageAction with data from selected package
        guard let selectedPackage = viewModel.selectedSavedPackage else { return }

        addPackageAction(selectedPackage)
    }
}

private extension WooSavedPackagesSelectionView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
        static let errorIconSize: CGFloat = 86
        static let ctaPadding: CGFloat = 60
    }

    enum Localization {
        static let loadingPackageError = NSLocalizedString(
            "wooShipping.savedPackagesSelectionView.loadingPackageError",
            value: "We are unable to load saved packages",
            comment: "Error message when loading saved packages failed in the shipping label creation flow"
        )
        static let retryCTA = NSLocalizedString(
            "wooShipping.savedPackagesSelectionView.retryCTA",
            value: "Retry",
            comment: "Button to retry loading saved packages in the shipping label creation flow"
        )
        static let emptyStateMessage = NSLocalizedString(
            "wooShipping.savedPackagesSelectionView.emptyStateMessage",
            value: "No saved packages yet",
            comment: "Message when there are no saved packages loaded in the shipping label creation flow"
        )
        static let createCustomPackageCTA = NSLocalizedString(
            "wooShipping.savedPackagesSelectionView.createCustomPackageCTA",
            value: "Create a custom package",
            comment: "Button to navigate to the custom package screen in the shipping label creation flow"
        )
    }
}
