import SwiftUI

final class WooShippingAddPackageViewModel: ObservableObject {
    // Holds values for all dimension input fields.
    // Using a dictionary so we can easily add/remove new types
    // if needed just by adding new case in enum
    @Published var fieldValues: [WooShippingAddPackageDimensionView.DimensionType: String] = [:]

    // Field values are invalid if one of them is empty
    var areFieldValuesInvalid: Bool {
        for (_, value) in fieldValues {
            if value.isEmpty {
                return true
            }
        }
        return fieldValues.count != WooShippingAddPackageDimensionView.DimensionType.allCases.count
    }
}

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

    enum PackageType: CaseIterable {
        case box, envelope
        var name: String {
            switch self {
            case .box:
                return Localization.box
            case .envelope:
                return Localization.envelope
            }
        }
    }

    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 16.0
        static let saveTemplateButtonID: String = "saveTemplateButtonID"
        static let scrollToDelay: Double = 0.5
    }

    @Environment(\.presentationMode) var presentationMode

    @StateObject private var customPackageViewModel = WooShippingAddPackageViewModel()
    // Holds type of selected package, it can be `custom`, `carrier` or `saved`
    @State var selectedPackageType = PackageProviderType.custom
    // Holds selected package type when custom package is selected, it can be `box` or `envelope`
    @State var packageType: PackageType = .box
    // Holds value for toggle that determines if we are showing button for saving the template
    @State var showSaveTemplate: Bool = false
    @State var packageTemplateName: String = ""
    @FocusState var packageTemplateNameFieldFocused: Bool
    @FocusState var focusedField: WooShippingAddPackageDimensionView.DimensionType?

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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                    HStack {
                        Text(Localization.packageType)
                            .font(.subheadline)
                        Spacer()
                    }
                    Menu {
                        // show selection
                        ForEach(PackageType.allCases, id: \.self) { option in
                            Button {
                                packageType = option
                            } label: {
                                Text(option.name)
                                    .bodyStyle()
                                if packageType == option {
                                    Image(uiImage: .checkmarkStyledImage)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(packageType.name)
                                .bodyStyle()
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding()
                    }
                    .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
                    AdaptiveStack(spacing: 8) {
                        ForEach(WooShippingAddPackageDimensionView.DimensionType.allCases, id: \.self) { dimensionType in
                            WooShippingAddPackageDimensionView(dimensionType: dimensionType, fieldValue: Binding(get: {
                                return self.customPackageViewModel.fieldValues[dimensionType] ?? ""
                            }, set: { value in
                                self.customPackageViewModel.fieldValues[dimensionType] = value
                            }), focusedField: _focusedField)
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Group {
                                Button(action: {
                                    onBackwardButtonTapped()
                                }, label: {
                                    Image(systemName: "chevron.backward")
                                })
                                .disabled(focusedField == WooShippingAddPackageDimensionView.DimensionType.allCases.first)
                                Button(action: {
                                    onForwardButtonTapped()
                                }, label: {
                                    Image(systemName: "chevron.forward")
                                })
                                .disabled(focusedField == WooShippingAddPackageDimensionView.DimensionType.allCases.last)
                                Spacer()
                                Button {
                                    dismissKeyboard()
                                } label: {
                                    Text(Localization.keyboardDoneButton)
                                        .bold()
                                }
                            }
                            .renderedIf(focusedField != nil)
                        }
                    }
                    Toggle(isOn: $showSaveTemplate) {
                        Text(Localization.saveNewPackageTemplate)
                            .font(.subheadline)
                    }
                    .tint(Color(.withColorStudio(.wooCommercePurple, shade: .shade60)))
                    if showSaveTemplate {
                        TextField("Enter a unique package name", text: $packageTemplateName)
                            .font(.body)
                            .focused($packageTemplateNameFieldFocused)
                            .padding()
                            .roundedBorder(cornerRadius: 8,
                                           lineColor: packageTemplateNameFieldFocused ? Color(UIColor.wooCommercePurple(.shade60)) : Color(.separator),
                                           lineWidth: packageTemplateNameFieldFocused ? 2 : 1)
                        Button(Localization.savePackageTemplate) {
                            savePackageAsTemplateButtonTapped()
                        }
                        .disabled(!validateCustomPackageInputFields())
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.bottom)
                        .id(Constants.saveTemplateButtonID) // Set the id for the button so we can scroll to it
                    }
                }
                .padding(.horizontal)
                .onChange(of: showSaveTemplate) { newValue in
                    packageTemplateNameFieldFocused = newValue
                }
                .onChange(of: packageTemplateNameFieldFocused) { focused in
                    if focused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scrollToDelay, execute: {
                            withAnimation {
                                proxy.scrollTo(Constants.saveTemplateButtonID, anchor: .bottom)
                            }
                        })
                    }
                }
            }
        }
        if !showSaveTemplate {
            Spacer()
            Button(Localization.addPackage) {
                addPackageButtonTapped()
            }
            .disabled(!validateCustomPackageInputFields())
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }

    private func onBackwardButtonTapped() {
        switch focusedField {
        case .length:
            return
        case .width:
            focusedField = .length
        case .height:
            focusedField = .width
        case nil:
            return
        }
    }

    private func onForwardButtonTapped() {
        switch focusedField {
        case .length:
            focusedField = .width
        case .width:
            focusedField = .height
        case .height:
            return
        case nil:
            return
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        packageTemplateNameFieldFocused = false
    }

    @ViewBuilder
    private var carrierPackageView: some View {
        // TODO: just a placeholder
        Spacer()
    }

    @ViewBuilder
    private var savedPackageView: some View {
        // TODO: just a placeholder
        SavedPackagesSelectionView(packages: [
            SavedPackageData(name: "Small Flat Rate Box", type: "Custom", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "DHL Express", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "Custom", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "USPS Priority Mail Flat Rate Boxes", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "Custom", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "USPS Priority Mail Flat Rate Boxes", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "Custom", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "Custom", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "DHL Express", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "Custom", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            SavedPackageData(name: "Small Flat Rate Box", type: "DHL Express", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
        ])
    }

    // MARK: - actions

    private func validateCustomPackageInputFields() -> Bool {
        guard !customPackageViewModel.areFieldValuesInvalid else {
            return false
        }
        if showSaveTemplate {
            return !packageTemplateName.isEmpty
        }
        return true
    }

    private func addPackageButtonTapped() {
        // TODO: implement adding a package
        guard validateCustomPackageInputFields() else { return }
    }

    private func savePackageAsTemplateButtonTapped() {
        // TODO: implement saving package as a template
        guard validateCustomPackageInputFields() else { return }
    }
}

struct WooShippingAddPackageDimensionView: View {
    enum DimensionType: CaseIterable {
        case length, width, height
        var name: String {
            switch self {
            case .length:
                return Localization.length
            case .width:
                return Localization.width
            case .height:
                return Localization.height
            }
        }
    }

    let dimensionType: DimensionType
    @Binding var fieldValue: String
    @FocusState var focusedField: WooShippingAddPackageDimensionView.DimensionType?

    var body: some View {
        VStack {
            HStack {
                Text(dimensionType.name)
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                TextField("", text: $fieldValue)
                    .keyboardType(.decimalPad)
                    .bodyStyle()
                    .focused($focusedField, equals: dimensionType)
                Text("cm")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: 8,
                           lineColor: focusedField == dimensionType ? Color(UIColor.wooCommercePurple(.shade60)) : Color(.separator),
                           lineWidth: focusedField == dimensionType ? 2 : 1)
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    WooShippingAddPackageView()
}

extension WooShippingAddPackageView {
    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.title",
                                                  value: "Add Package",
                                                  comment: "Title for the Add Package screen")
        static let packageType = NSLocalizedString("wooShipping.createLabel.addPackage.packageType",
                                                   value: "Package type",
                                                   comment: "Info label for selecting package type")
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
        static let box = NSLocalizedString("wooShipping.createLabel.addPackage.box",
                                           value: "Box",
                                           comment: "Info label for selected box as a package type")
        static let envelope = NSLocalizedString("wooShipping.createLabel.addPackage.envelope",
                                                value: "Envelope",
                                                comment: "Info label for selected envelope as a package type")
        static let saveNewPackageTemplate = NSLocalizedString("wooShipping.createLabel.addPackage.saveNewPackageTemplate",
                                                              value: "Save this as a new package template",
                                                              comment: "Info label for saving package as a new template toggle")
        static let savePackageTemplate = NSLocalizedString("wooShipping.createLabel.addPackage.savePackageTemplate",
                                                           value: "Save package template",
                                                           comment: "Button for saving package as a new template")
        static let keyboardDoneButton = NSLocalizedString(
            "wooShipping.createLabel.addPackage.keyboard.toolbar.done.button.title",
            value: "Done",
            comment: "The title for a button to dismiss the keyboard on the order creation/editing screen")
    }
}

extension WooShippingAddPackageDimensionView {
    enum Localization {
        static let length = NSLocalizedString("wooShipping.createLabel.addPackage.length",
                                              value: "Length",
                                              comment: "Info label for length input field")
        static let width = NSLocalizedString("wooShipping.createLabel.addPackage.width",
                                             value: "Width",
                                             comment: "Info label for width input field")
        static let height = NSLocalizedString("wooShipping.createLabel.addPackage.height",
                                              value: "Height",
                                              comment: "Info label for height input field")
    }
}

protocol SavedPackageDataRepresentable {
    var name: String { get }
    var type: String { get }
    var dimensions: String { get }
    var weight: String { get }
}

struct SavedPackageData: SavedPackageDataRepresentable {
    let name: String
    let type: String
    let dimensions: String
    let weight: String
}

struct SavedPackagesSelectionView: View {
    @State private var selectedPackageIndex: Int? = nil  // Track the selected package index
    let packages: [SavedPackageDataRepresentable]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            List {
                ForEach(packages.indices, id: \.self) { index in
                    PackageOptionView(
                        isSelected: selectedPackageIndex == index, // Check if this package is selected
                        package: packages[index],
                        showTopDivider: false,
                        action: {
                            selectedPackageIndex = selectedPackageIndex == index ? nil : index
                        }
                    )
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 16
                    }
                    .swipeActions {
                        Button {
                            // remove package
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(Color.withColorStudio(name: .red, shade: .shade50))
                    }
                }
                .listRowInsets(.zero)
            }
            .listStyle(.plain)
            Divider()
            Button(WooShippingAddPackageView.Localization.addPackage) {
            }
            .disabled(selectedPackageIndex == nil || packages.isEmpty)
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }
}

struct PackageOptionView: View {
    var isSelected: Bool
    var package: SavedPackageDataRepresentable
    var showTopDivider: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color(.withColorStudio(.wooCommercePurple, shade: .shade60)) : .gray)
                .font(.title)
            VStack(alignment: .leading, spacing: 4) {
                Text(package.type)
                    .captionStyle()
                Text(package.name)
                    .bodyStyle()
                HStack {
                    Text(package.dimensions)
                    Text("•")
                    Text(package.weight)
                }
                .subheadlineStyle()
                .foregroundColor(.gray)
            }
            .padding(.leading, 4)
            Spacer()
        }
        .padding(16)
        .onTapGesture {
            action()
        }
    }
}
