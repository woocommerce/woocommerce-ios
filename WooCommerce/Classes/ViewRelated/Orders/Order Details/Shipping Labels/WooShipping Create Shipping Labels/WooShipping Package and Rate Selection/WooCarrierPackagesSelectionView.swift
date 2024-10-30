import SwiftUI

// Holds the data needed to display a tab in list of Carrier packages.
struct WooShippingPackagesCarrierTab: Identifiable {
    let id: WooShippingCarrier
    let packageGroups: [WooPackageGroup]
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
                            isSelected: selectedPackageId == package.id, // Check if this package is selected
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

    let carriersPackages: [WooShippingPackagesCarrierTab]
    let tabs: [TopTabItem<EmptyView>]
    let addPackageAction: (WooPackageDataRepresentable) -> Void

    @State private var selectedTabIndex: Int?
    @State private var selectedPackageId: UUID? = nil

    init(carriersPackages: [WooShippingPackagesCarrierTab],
         addPackageAction: @escaping (WooPackageDataRepresentable) -> Void) {
        self.carriersPackages = carriersPackages
        self.tabs = carriersPackages.map { carrierTab in
            return TopTabItem(name: carrierTab.id.name, icon: carrierTab.id.logo, content: {
                EmptyView()
            })
        }
        _selectedTabIndex = State(initialValue: carriersPackages.isEmpty ? nil : 0)
        self.addPackageAction = addPackageAction
    }

    var body: some View {
        if let selectedTabIndex, tabs.isNotEmpty {
            VStack(spacing: 0) {
                TopTabView(tabs: tabs,
                           showContent: .constant(false),
                           selectedTabIndex: $selectedTabIndex,
                           tabsContainerHorizontalPadding: nil,
                           selectedStateColor: Color.accentColor,
                           unselectedStateColor: .secondary,
                           selectedTabIndicatorHeight: Constants.selectedTabIndicatorHeight,
                           tabPadding: Constants.tabPadding,
                           tabsNameFont: Font.subheadline.bold(),
                           tabItemContentHorizontalPadding: Constants.tabItemContentHorizontalPadding,
                           tabItemContentVerticalPadding: Constants.tabItemContentVerticalPadding)
                WooCarrierPackagesView(carrierTab: carriersPackages[selectedTabIndex],
                                       selectedPackageId: $selectedPackageId)
                Spacer()
                Divider()
                Button(WooShippingAddPackageView.Localization.addPackage) {
                    addPackageButtonTapped()
                }
                .disabled(selectedPackageId == nil)
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
        // call addPackageAction with data
        if let selectedPackageId {
            for carriersPackage in carriersPackages {
                for packageGroup in carriersPackage.packageGroups {
                    for packageItem in packageGroup.packages {
                        if selectedPackageId == packageItem.id {
                            addPackageAction(packageItem)
                            return
                        }
                    }
                }
            }
        }
    }
}
