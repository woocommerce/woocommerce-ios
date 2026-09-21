import Combine
import ParcelFittingCheck
import SwiftUI

struct WooShippingAddPackageView: View {
    enum PackageProviderType: CaseIterable {
        case custom, carrier, saved
        var name: String {
            switch self {
            case .custom:
                return Localization.custom
            case .carrier:
                return Localization.carrier
            case .saved:
                return Localization.saved
            }
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var packagesViewModel: WooShippingAddPackageViewModel
    @ObservedObject var customPackageViewModel: WooShippingAddCustomPackageViewModel

    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void
    let arAnalytics: ParcelFittingAnalyticsTracking
    weak var arDelegate: ParcelFittingDelegate?

    @State private var cancellable: AnyCancellable?

    @Environment(\.shippingWeightUnit) private var weightUnit
    @Environment(\.shippingDimensionsUnit) private var dimensionsUnit
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(selectedPackage: WooShippingPackageDataRepresentable? = nil,
         addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void,
         arAnalytics: ParcelFittingAnalyticsTracking = ParcelFittingAnalyticsAdaptor(),
         arDelegate: ParcelFittingDelegate? = nil) {
        self.addPackageAction = addPackageAction
        self.arAnalytics = arAnalytics
        self.arDelegate = arDelegate
        packagesViewModel = WooShippingAddPackageViewModel(selectedPackage: selectedPackage)
        switch selectedPackage?.source {
        case .custom:
            customPackageViewModel = WooShippingAddCustomPackageViewModel(selectedPackage: selectedPackage)
        default:
            customPackageViewModel = WooShippingAddCustomPackageViewModel()
        }
    }

    // MARK: - UI

    var body: some View {
        NavigationView {
            VStack {
                packageTypeSelectorView
                selectedPackageTypeView
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text(Localization.cancel)
                    })
                }
                if packagesViewModel.isARParcelFittingAvailable {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            presentARFlow()
                        } label: {
                            Image(systemName: "camera")
                        }
                    }
                }
            }
            .navigationTitle(packagesViewModel.previousSelectedPackage != nil ? Localization.editPackage :  Localization.addPackage)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .task {
            await packagesViewModel.loadPackages()
        }
        .notice($packagesViewModel.notice)
    }

    // MARK: - Computed Properties

    private var selectedPackageTypeIndex: Binding<Int> {
        Binding(
            get: {
                PackageProviderType.allCases.firstIndex(of: packagesViewModel.selectedPackageType) ?? 0
            },
            set: { newIndex in
                if let newType = PackageProviderType.allCases[safe: newIndex] {
                    packagesViewModel.selectedPackageType = newType
                }
            }
        )
    }

    private var packageTypeTabs: [TopTabItem<EmptyView>] {
        PackageProviderType.allCases.map { packageType in
            TopTabItem(name: packageType.name, content: { EmptyView() })
        }
    }

    // MARK: UI components

    @ViewBuilder
    private var selectedPackageTypeView: some View {
        switch packagesViewModel.selectedPackageType {
        case .custom:
            WooAddCustomPackageView(viewModel: customPackageViewModel,
                                    addPackageAction: addPackageAction)
        case .carrier:
            WooCarrierPackagesSelectionView(viewModel: packagesViewModel,
                                            addPackageAction: addPackageAction,
                                            addingCustomPackageHandler: {
                packagesViewModel.selectedPackageType = .custom
            })
        case .saved:
            WooSavedPackagesSelectionView(viewModel: packagesViewModel,
                                          addPackageAction: addPackageAction,
                                          addingCustomPackageHandler: {
                packagesViewModel.selectedPackageType = .custom
            })
        }
    }

    private func presentARFlow() {
        guard let arDelegate,
              let presenter = UIApplication.wooKeyWindow?.topmostPresentedViewController else { return }

        ParcelFittingCheckPresenter.presentUnifiedFlow(
            from: presenter,
            unit: packagesViewModel.arDimensionUnit,
            carriers: packagesViewModel.parcelPresetCarriers,
            starredPackageIDs: packagesViewModel.starredCarriersPackages,
            tintColor: .withColorStudio(.wooCommercePurple, shade: .shade60),
            analytics: arAnalytics,
            delegate: arDelegate
        )
    }

    private var packageTypeSelectorView: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                TopTabView(
                    tabs: packageTypeTabs,
                    showContent: false,
                    selectedTabIndex: selectedPackageTypeIndex,
                    tabsContainerHorizontalPadding: nil,
                    selectedStateColor: .accentColor,
                    unselectedStateColor: .secondary,
                    selectedTabIndicatorHeight: 3.0,
                    tabPadding: 0,
                    tabsNameFont: .subheadline.bold(),
                    tabItemContentHorizontalPadding: 16.0,
                    tabItemContentVerticalPadding: 9.0
                )
                .padding(.vertical)
            } else {
                Picker("", selection: $packagesViewModel.selectedPackageType) {
                    ForEach(PackageProviderType.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
        }
    }
}

struct WooShippingAddPackageUnitInputView: View {
    let unitType: WooShippingPackageUnitType
    let unit: String
    @Binding var fieldValue: String
    @FocusState var focusedField: WooShippingPackageUnitType?

    private var isFocused: Bool {
        return focusedField == unitType
    }

    var body: some View {
        VStack {
            HStack {
                Text(unitType.name)
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                TextField("", text: $fieldValue)
                    .keyboardType(.decimalPad)
                    .bodyStyle()
                    .focused($focusedField, equals: unitType)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: 8,
                           lineColor: isFocused ? Color.accentColor : Color(.separator),
                           lineWidth: isFocused ? 2 : 1)
        }
        .frame(minHeight: 48)
    }
}

extension WooShippingAddPackageView {
    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.title",
                                                  value: "Add Package",
                                                  comment: "Title for the Add Package screen")
        static let cancel = NSLocalizedString("wooShipping.createLabel.addPackage.cancel",
                                              value: "Cancel",
                                              comment: "Cancel button in navigation bar to dismiss the screen")
        static let custom = NSLocalizedString("wooShipping.createLabel.addPackage.custom",
                                              value: "Custom",
                                              comment: "Info label for custom package option")
        static let carrier = NSLocalizedString("wooShipping.createLabel.addPackage.carrier",
                                               value: "Carrier",
                                               comment: "Info label for carrier package option")
        static let saved = NSLocalizedString("wooShipping.createLabel.addPackage.saved",
                                             value: "Saved",
                                             comment: "Info label for saved package option")
        static let selectPackage = NSLocalizedString("wooShipping.createLabel.addPackage.selectPackage",
                                                     value: "Select Package",
                                                     comment: "Title for the Add Package screen Select Package button")
        static let addPackageDetails = NSLocalizedString("wooShipping.createLabel.addPackage.addPackageDetails",
                                                         value: "Add Package Details",
                                                         comment: "Title for the Add Package screen Add Package Details button")
        static let editPackage = NSLocalizedString("wooShipping.createLabel.editPackage.title",
                                                   value: "Edit Package",
                                                   comment: "Title for the Edit Package screen")
        static let done = NSLocalizedString("wooShipping.createLabel.editPackage.done",
                                            value: "Done",
                                            comment: "Title for the Edit Package screen Done button")
        static let useSelectedPackage = NSLocalizedString("wooShipping.createLabel.editPackage.useSelectedPackage",
                                                          value: "Use Selected Package",
                                                          comment: "Title for the Edit Package screen Use Selected Package button")
    }
}
