import SwiftUI
import Combine
import struct Yosemite.ShippingLabelStoreOptions

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

    // Holds type of selected package, it can be `custom`, `carrier` or `saved`
    @State var selectedPackageType = PackageProviderType.custom
    @StateObject var packagesRepository: WooShippingPackagesRepository
    @State var customPackageViewModel: WooShippingAddCustomPackageViewModel?
    @ObservedObject var createLabelsViewModel: WooShippingCreateLabelsViewModel

    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    @State private var cancellable: AnyCancellable?

    init(createLabelsViewModel: WooShippingCreateLabelsViewModel,
         packagesRepository: WooShippingPackagesRepository = WooShippingPackagesRepository.shared,
         addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void) {
        self.createLabelsViewModel = createLabelsViewModel
        self._packagesRepository = StateObject(wrappedValue: packagesRepository)
        self.addPackageAction = addPackageAction
    }

    private func loadCustomPackageViewModelWithStoreOptions(_ storeOptions: ShippingLabelStoreOptions?) {
        guard let storeOptions, customPackageViewModel == nil else { return }
        customPackageViewModel = WooShippingAddCustomPackageViewModel(dimensionsUnit: storeOptions.dimensionUnit,
                                                                      weightUnit: storeOptions.weightUnit)
    }

    // MARK: - UI

    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedPackageType) {
                    ForEach(PackageProviderType.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
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
            }
            .navigationTitle(Localization.addPackage)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .task {
            packagesRepository.loadPackages()
        }
        .onAppear() {
            if let storeOptions = createLabelsViewModel.storeOptions {
                loadCustomPackageViewModelWithStoreOptions(storeOptions)
            }
            else {
                cancellable = createLabelsViewModel.$storeOptions
                    .receive(on: DispatchQueue.main)
                    .sink { storeOptions in
                        loadCustomPackageViewModelWithStoreOptions(storeOptions)
                    }
            }
        }
    }

    // MARK: UI components

    @ViewBuilder
    private var selectedPackageTypeView: some View {
        switch selectedPackageType {
        case .custom:
            customPackageView
        case .carrier:
            carrierPackageView
        case .saved:
            savedPackageView
        }
    }

    @ViewBuilder
    private var customPackageView: some View {
        if let customPackageViewModel {
            WooAddCustomPackageView(viewModel: customPackageViewModel) { packageData in
                addPackageAction(packageData)
            }
        }
        else {
            storeOptionsLoadingView
        }
    }

    private var storeOptionsLoadingView: some View {
        VStack {
            HStack {
                Spacer()
                if createLabelsViewModel.isLoadingStoreOptions {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                else {
                    Button {
                        createLabelsViewModel.loadStoreOptions { storeOptions in
                            loadCustomPackageViewModelWithStoreOptions(storeOptions)
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var carrierPackageView: some View {
        WooCarrierPackagesSelectionView(viewModel: WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)) { packageData in
            addPackageAction(packageData)
        }
    }

    @ViewBuilder
    private var savedPackageView: some View {
        WooSavedPackagesSelectionView(viewModel: WooSavedPackagesSelectionViewModel(packagesRepository: packagesRepository)) { packageData in
            addPackageAction(packageData)
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
    }
}
