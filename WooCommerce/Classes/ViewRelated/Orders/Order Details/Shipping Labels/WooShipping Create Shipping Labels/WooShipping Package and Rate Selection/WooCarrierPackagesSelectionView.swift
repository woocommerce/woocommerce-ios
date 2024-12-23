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
    let id: UUID = UUID()
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
    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    init(viewModel: WooShippingAddPackageViewModel,
         addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void) {
        self.viewModel = viewModel
        self.addPackageAction = addPackageAction
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.selectedCarriersTabIndex != nil, viewModel.carrierTabs.isNotEmpty {
                TopTabView(tabs: viewModel.carrierTabs,
                           showContent: .constant(false),
                           selectedTabIndex: $viewModel.selectedCarriersTabIndex,
                           tabsContainerHorizontalPadding: nil,
                           selectedStateColor: Color.accentColor,
                           unselectedStateColor: .secondary,
                           selectedTabIndicatorHeight: Constants.selectedTabIndicatorHeight,
                           tabPadding: Constants.tabPadding,
                           tabsNameFont: Font.subheadline.bold(),
                           tabItemContentHorizontalPadding: Constants.tabItemContentHorizontalPadding,
                           tabItemContentVerticalPadding: Constants.tabItemContentVerticalPadding)
            }
            // Show extra loading indicator in case there are no packages
            else if viewModel.isLoadingPackages {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }
            else {
                Button {
                    Task {
                        await viewModel.loadPackages()
                    }
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                }
                .padding()
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
            Button(WooShippingAddPackageView.Localization.addPackage) {
                addPackageButtonTapped()
            }
            .disabled(viewModel.selectedCarriersPackageId == nil)
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }

    private func addPackageButtonTapped() {
        // call addPackageAction with data from selected package
        guard let selectedPackage = viewModel.selectedCarriersPackage  else { return }

        addPackageAction(selectedPackage)
    }
}
