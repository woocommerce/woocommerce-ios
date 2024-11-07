import SwiftUI

// Holds the data needed to display a tab in list of Carrier packages.
struct WooShippingPackagesCarrierTab: Identifiable {
    let carrier: WooShippingCarrier
    let packageGroups: [WooPackageGroup]

    var id: String {
        return carrier.name
    }
}

struct WooPackageGroup {
    let id: UUID = UUID()
    let name: String
    let packages: [any WooPackageDataRepresentable]
}

struct WooCarrierPackageData: WooPackageDataRepresentable {
    let id: UUID = UUID()
    let name: String
    let type: String
    let packageType: String
    let dimensions: String
    let weight: String
}

struct WooCarrierPackagesView: View {
    let carrierTab: WooShippingPackagesCarrierTab
    @Binding var selectedPackageId: UUID?  // Track the selected package index
    @State private var starredPackages: Set<UUID> = []

    var body: some View {
        List {
            ForEach(carrierTab.packageGroups, id: \.id) { packageGroup in
                Section {
                    ForEach(packageGroup.packages, id: \.id) { package in
                        PackageOptionView(
                            isSelected: selectedPackageId == package.id,
                            package: package,
                            showTopDivider: false,
                            showType: false,
                            tapAction: {
                                selectedPackageId = selectedPackageId == package.id ? nil : package.id
                            },
                            starAction: {
                                // Just temporary, will be replaced with proper logic
                                if starredPackages.contains(package.id) {
                                    starredPackages.remove(package.id)
                                }
                                else {
                                    starredPackages.insert(package.id)
                                }
                            },
                            starred: starredPackages.contains(package.id)
                        )
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            return 16
                        }
                    }
                } header: {
                    HStack {
                        Text(packageGroup.name.uppercased())
                            .foregroundColor(.secondary)
                            .fontWeight(.regular)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .background(Color.clear)
                }
                .listRowInsets(.zero)
            }
        }
        .listStyle(.plain)
    }
}

struct WooCarrierPackagesSelectionView: View {
    enum Constants {
        static let tabItemContentHorizontalPadding: CGFloat = 16.0
        static let tabItemContentVerticalPadding: CGFloat = 9.0
        static let selectedTabIndicatorHeight: CGFloat = 3.0
        static let tabPadding: CGFloat = 9.0
    }

    @ObservedObject private var viewModel: WooCarrierPackagesSelectionViewModel
    let addPackageAction: (WooPackageDataRepresentable) -> Void

    init(carrierTabs: [WooShippingPackagesCarrierTab],
         addPackageAction: @escaping (WooPackageDataRepresentable) -> Void) {
        let tabs = carrierTabs.map { carrierTab in
            return TopTabItem(name: carrierTab.carrier.name, icon: carrierTab.carrier.logo, content: {
                EmptyView()
            })
        }
        viewModel = WooCarrierPackagesSelectionViewModel(carrierTabs: carrierTabs, tabs: tabs)
        self.addPackageAction = addPackageAction
    }

    var body: some View {
        if viewModel.selectedTabIndex != nil, viewModel.tabs.isNotEmpty {
            VStack(spacing: 0) {
                TopTabView(tabs: viewModel.tabs,
                           showContent: .constant(false),
                           selectedTabIndex: $viewModel.selectedTabIndex,
                           tabsContainerHorizontalPadding: nil,
                           selectedStateColor: Color.accentColor,
                           unselectedStateColor: .secondary,
                           selectedTabIndicatorHeight: Constants.selectedTabIndicatorHeight,
                           tabPadding: Constants.tabPadding,
                           tabsNameFont: Font.subheadline.bold(),
                           tabItemContentHorizontalPadding: Constants.tabItemContentHorizontalPadding,
                           tabItemContentVerticalPadding: Constants.tabItemContentVerticalPadding)
                if let selectedCarrierTab = viewModel.selectedCarrierTab {
                    WooCarrierPackagesView(carrierTab: selectedCarrierTab,
                                           selectedPackageId: $viewModel.selectedPackageId)
                }
                Spacer()
                Divider()
                Button(WooShippingAddPackageView.Localization.addPackage) {
                    addPackageButtonTapped()
                }
                .disabled(viewModel.selectedPackageId == nil)
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
        else {
            // TODO: add some kind of empty state view
            EmptyView()
        }
    }

    private func addPackageButtonTapped() {
        // call addPackageAction with data from selected package
        guard let selectedPackage = viewModel.selectedPackage else { return }

        addPackageAction(selectedPackage)
    }
}
