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
    let dimensions: String
    let weight: String
}

struct WooCarrierPackagesTabView: View {
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
                            packageType: nil,
                            showTopDivider: false,
                            tapAction: {
                                selectedPackageId = selectedPackageId == package.id ? nil : package.id
                            },
                            starAction: {
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

    @State private var selectedTab: Int = 0
    @State private var selectedPackageId: UUID? = nil

    init(carriersPackages: [WooShippingPackagesCarrierTab]) {
        self.carriersPackages = carriersPackages
        self.tabs = carriersPackages.map { carrierTab in
            return TopTabItem(name: carrierTab.id.name, icon: carrierTab.id.logo, content: {
                EmptyView()
            })
        }
    }

    var body: some View {
        if tabs.isNotEmpty {
            VStack(spacing: 0) {
                TopTabView(selectedTab: $selectedTab,
                           tabs: tabs,
                           showContent: .constant(false),
                           tabsContainerHorizontalPadding: nil,
                           selectedStateColor: Color.accentColor,
                           unselectedStateColor: .secondary,
                           selectedTabIndicatorHeight: Constants.selectedTabIndicatorHeight,
                           tabPadding: Constants.tabPadding,
                           tabsNameFont: Font.subheadline.bold(),
                           tabItemContentHorizontalPadding: Constants.tabItemContentHorizontalPadding,
                           tabItemContentVerticalPadding: Constants.tabItemContentVerticalPadding)
                WooCarrierPackagesTabView(carrierTab: carriersPackages[selectedTab],
                                          selectedPackageId: $selectedPackageId)
                Spacer()
                Divider()
                Button(WooShippingAddPackageView.Localization.addPackage) {
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
}
