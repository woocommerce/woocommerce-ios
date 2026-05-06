import SwiftUI
import Foundation

// Holds the data needed to display a tab in list of Carrier packages.
struct WooShippingCarrierPackages: Identifiable {
    let carrier: WooShippingCarrier
    let packageGroups: [WooPackageGroup]

    var id: String {
        return carrier.name
    }
}

struct WooPackageGroup {
    let id = UUID()
    let name: String
    let packages: [any WooShippingPackageDataRepresentable]
}

struct WooCarrierPackagesView: View {
    let carrierTab: WooShippingCarrierPackages
    @Binding var selectedPackageId: String?  // Track the selected package index
    @Binding var starredPackages: Set<String>
    let tapAction: (String) -> Void
    let starAction: (String) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        ScrollViewReader { scroll in
            List {
                ForEach(carrierTab.packageGroups, id: \.id) { packageGroup in
                    Section {
                        ForEach(packageGroup.packages, id: \.id) { package in
                            WooShippingPackageOptionView(
                                isSelected: selectedPackageId == package.id,
                                package: package,
                                showTopDivider: false,
                                showSource: false,
                                tapAction: {
                                    tapAction(package.id)
                                },
                                starAction: {
                                    starAction(package.id)
                                },
                                starred: starredPackages.contains(package.id)
                            )
                            .alignmentGuide(.listRowSeparatorLeading) { _ in
                                return 16
                            }
                            .id(package.id)
                        }
                    } header: {
                        HStack {
                            Text(packageGroup.name.uppercased())
                                .foregroundColor(.secondary)
                                .captionStyle()
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .background(Color.clear)
                    }
                    .listRowInsets(.zero)
                }
            }
            .task {
                scroll.scrollTo(selectedPackageId)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await onRefresh()
        }
    }
}

struct WooCarrierPackagesSelectionView: View {
    enum Constants {
        static let tabItemContentHorizontalPadding: CGFloat = 16.0
        static let tabItemContentVerticalPadding: CGFloat = 9.0
        static let selectedTabIndicatorHeight: CGFloat = 3.0
        static let tabPadding: CGFloat = 9.0
    }

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
            if viewModel.carrierTabs.isNotEmpty {
                TopTabView(tabs: viewModel.carrierTabs,
                           showContent: false,
                           selectedTabIndex: $viewModel.selectedCarriersTabIndex,
                           tabsContainerHorizontalPadding: nil,
                           selectedStateColor: Color.accentColor,
                           unselectedStateColor: .secondary,
                           selectedTabIndicatorHeight: Constants.selectedTabIndicatorHeight,
                           tabPadding: Constants.tabPadding,
                           tabsNameFont: Font.subheadline.bold(),
                           tabItemContentHorizontalPadding: Constants.tabItemContentHorizontalPadding,
                           tabItemContentVerticalPadding: Constants.tabItemContentVerticalPadding)
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

            if let selectedCarrierTab = viewModel.selectedCarrierTab {
                WooCarrierPackagesView(carrierTab: selectedCarrierTab,
                                       selectedPackageId: $viewModel.selectedCarriersPackageId,
                                       starredPackages: $viewModel.starredCarriersPackages,
                                       tapAction: { packageID in
                    viewModel.selectedCarriersPackageId = viewModel.selectedCarriersPackageId == packageID ? nil : packageID
                }, starAction: { packageID in
                    viewModel.starUnstarPackage(packageID, carrierID: selectedCarrierTab.carrier.rawValue)
                }, onRefresh: {
                    await viewModel.loadPackages()
                })
            }
            Spacer()
            Divider()
            Button(selectionButtonText) {
                addPackageButtonTapped()
            }
            .renderedIf(viewModel.carrierTabs.isNotEmpty)
            .disabled(selectionButtonDisabled)
            .if(viewModel.previousSelectedAndSelectedCarriersPackageAreSame) {
                $0.buttonStyle(SecondaryButtonStyle())
            }
            .if(!viewModel.previousSelectedAndSelectedCarriersPackageAreSame) {
                $0.buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
    }
}

private extension WooCarrierPackagesSelectionView {
    var selectionButtonDisabled: Bool {
        viewModel.selectedCarriersPackageId == nil
    }

    var selectionButtonText: String {
        if selectionButtonDisabled {
            return WooShippingAddPackageView.Localization.selectPackage
        }
        if let previousSelectedPackage = viewModel.previousSelectedPackage {
            if previousSelectedPackage.id == viewModel.selectedCarriersPackageId {
                return WooShippingAddPackageView.Localization.done
            }
            return WooShippingAddPackageView.Localization.useSelectedPackage
        }
        return WooShippingAddPackageView.Localization.addPackage
    }

    @ViewBuilder
    var loadingStateView: some View {
        Spacer()
        ProgressView()
            .progressViewStyle(.circular)
        Spacer()
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
            Image(uiImage: .deliveryIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.errorIconSize, height: Layout.errorIconSize)
            Text(Localization.emptyStateMessage)
                .multilineTextAlignment(.center)
                .bold()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
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

    func addPackageButtonTapped() {
        // call addPackageAction with data from selected package
        guard let selectedPackage = viewModel.selectedCarriersPackage  else { return }

        addPackageAction(selectedPackage)
    }

}

private extension WooCarrierPackagesSelectionView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
        static let errorIconSize: CGFloat = 86
        static let ctaPadding: CGFloat = 60
    }

    enum Localization {
        static let loadingPackageError = NSLocalizedString(
            "wooShipping.packagesSelectionView.loadingPackageError",
            value: "We are unable to load carrier packages",
            comment: "Error message when loading carrier packages failed in the shipping label creation flow"
        )
        static let retryCTA = NSLocalizedString(
            "wooShipping.packagesSelectionView.retryCTA",
            value: "Retry",
            comment: "Button to retry loading carrier packages in the shipping label creation flow"
        )
        static let emptyStateMessage = NSLocalizedString(
            "wooShipping.packagesSelectionView.emptyStateMessage",
            value: "No carrier information found",
            comment: "Message when there are no carrier packages loaded in the shipping label creation flow"
        )
        static let createCustomPackageCTA = NSLocalizedString(
            "wooShipping.packagesSelectionView.createCustomPackageCTA",
            value: "Create a custom package",
            comment: "Button to navigate to the custom package screen in the shipping label creation flow"
        )
    }
}
