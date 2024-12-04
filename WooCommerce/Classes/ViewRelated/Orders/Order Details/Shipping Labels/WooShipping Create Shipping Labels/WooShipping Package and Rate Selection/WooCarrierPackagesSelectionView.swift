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
    @ObservedObject private var viewModel: WooCarrierPackagesSelectionViewModel

    init(viewModel: WooCarrierPackagesSelectionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if let packageGroups = viewModel.selectedCarrierTab?.packageGroups {
                ForEach(packageGroups, id: \.id) { packageGroup in
                    Section {
                        ForEach(packageGroup.packages, id: \.id) { package in
                            PackageOptionView(
                                isSelected: viewModel.selectedPackageId == package.id,
                                package: package,
                                showTopDivider: false,
                                showSource: false,
                                tapAction: {
                                    viewModel.selectedPackageId = viewModel.selectedPackageId == package.id ? nil : package.id
                                },
                                starAction: {
                                    // Just temporary, will be replaced with proper logic
                                    if viewModel.isPackageStarred(package) {
                                        Task {
                                            await viewModel.unstarPackage(package)
                                        }
                                    }
                                    else {
                                        Task {
                                            await viewModel.starPackage(package)
                                        }
                                    }
                                },
                                starred: viewModel.isPackageStarred(package),
                                tipTitle: (packageGroups.first?.id == packageGroup.id && packageGroup.packages.first?.id == package.id)
                                                ? Text(Localization.starTipTitle) : nil,
                                tipMessage: Text(Localization.starTipMessage),
                                tipImage: Image(systemName: "star")
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
    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    init(viewModel: WooCarrierPackagesSelectionViewModel,
         addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void) {
        self.viewModel = viewModel
        self.addPackageAction = addPackageAction
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.selectedTabIndex != nil, viewModel.tabs.isNotEmpty {
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
            }
            if viewModel.selectedCarrierTab != nil {
                WooCarrierPackagesView(viewModel: viewModel)
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

    private func addPackageButtonTapped() {
        // call addPackageAction with data from selected package
        guard let selectedPackage = viewModel.selectedPackage else { return }

        addPackageAction(selectedPackage)
    }
}

private extension WooCarrierPackagesView {
    enum Localization {
        static let starTipTitle = NSLocalizedString("wooShipping.createLabels.packageOption.tip.title",
                                                    value: "Save frequently used packages",
                                                    comment: "Title of the tip for starring packages in the Woo Shipping label creation flow.")
        static let starTipMessage = NSLocalizedString("wooShipping.createLabels.packageOption.tip.message",
                                                      value: "Tap the star to add or remove a package from the Saved tab.",
                                                      comment: "Message for the tip for starring packages in the Woo Shipping label creation flow.")
    }
}
