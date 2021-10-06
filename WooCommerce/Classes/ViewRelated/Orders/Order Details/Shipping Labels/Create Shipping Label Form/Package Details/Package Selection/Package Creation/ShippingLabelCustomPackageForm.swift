import SwiftUI
import Combine

/// Form to create a new custom package to use with shipping labels.
struct ShippingLabelCustomPackageForm: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var viewModel: ShippingLabelCustomPackageFormViewModel
    @State private var showingPackageTypes = false
    let safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
                ListHeaderView(text: Localization.customPackageHeader, alignment: .left)
                    .padding(.horizontal, insets: safeAreaInsets)

                // Package Type & Name
                VStack(spacing: 0) {
                    Divider()
                    VStack(spacing: 0) {
                        // Package type
                        TitleAndValueRow(title: Localization.packageTypeLabel,
                                         value: .placeholder(viewModel.packageType.localizedName),
                                         selectable: true) {
                            showingPackageTypes.toggle()
                        }
                        .sheet(isPresented: $showingPackageTypes, content: {
                            SelectionList(title: Localization.packageTypeLabel,
                                          items: ShippingLabelCustomPackageFormViewModel.PackageType.allCases,
                                          contentKeyPath: \.localizedName,
                                          selected: $viewModel.packageType)
                        })

                        Divider()
                            .padding(.leading, Constants.horizontalPadding)

                        // Package name
                        TitleAndTextFieldRow(title: Localization.packageNameLabel,
                                             placeholder: Localization.packageNamePlaceholder,
                                             text: $viewModel.packageName,
                                             symbol: nil,
                                             keyboardType: .default)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                    Divider()
                    ValidationErrorRow(errorMessage: Localization.getErrorMessage(for: viewModel.packageName))
                        .background(Color(.listBackground).ignoresSafeArea(.container, edges: .horizontal))
                        .padding(.horizontal, insets: safeAreaInsets)
                        .renderedIf(!viewModel.isNameValidated)
                }

                // Package Dimensions
                VStack(spacing: 0) {
                    Divider()

                    // Package length
                    VStack(spacing: 0) {
                        TitleAndTextFieldRow(title: Localization.lengthLabel,
                                             placeholder: "0",
                                             text: $viewModel.packageLength,
                                             symbol: viewModel.lengthUnit,
                                             keyboardType: .decimalPad)
                        Divider()
                            .padding(.leading, Constants.horizontalPadding)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                    VStack(spacing: 0) {
                        ValidationErrorRow(errorMessage: Localization.getErrorMessage(for: viewModel.packageLength))
                            .background(Color(.listBackground).ignoresSafeArea(.container, edges: .horizontal))
                        Divider()
                            .padding(.leading, Constants.horizontalPadding)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .renderedIf(!viewModel.isLengthValidated)

                    // Package width
                    VStack(spacing: 0) {
                        TitleAndTextFieldRow(title: Localization.widthLabel,
                                             placeholder: "0",
                                             text: $viewModel.packageWidth,
                                             symbol: viewModel.lengthUnit,
                                             keyboardType: .decimalPad)
                        Divider()
                            .padding(.leading, Constants.horizontalPadding)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                    VStack(spacing: 0) {
                        ValidationErrorRow(errorMessage: Localization.getErrorMessage(for: viewModel.packageWidth))
                            .background(Color(.listBackground).ignoresSafeArea(.container, edges: .horizontal))
                        Divider()
                            .padding(.leading, Constants.horizontalPadding)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .renderedIf(!viewModel.isWidthValidated)

                    // Package height
                    TitleAndTextFieldRow(title: Localization.heightLabel,
                                         placeholder: "0",
                                         text: $viewModel.packageHeight,
                                         symbol: viewModel.lengthUnit,
                                         keyboardType: .decimalPad)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                    Divider()
                    ValidationErrorRow(errorMessage: Localization.getErrorMessage(for: viewModel.packageHeight))
                        .background(Color(.listBackground).ignoresSafeArea(.container, edges: .horizontal))
                        .padding(.horizontal, insets: safeAreaInsets)
                        .renderedIf(!viewModel.isHeightValidated)
                }

                // Package Weight
                VStack(spacing: 0) {
                    Divider()
                    TitleAndTextFieldRow(title: Localization.emptyPackageWeightLabel,
                                         placeholder: "0",
                                         text: $viewModel.emptyPackageWeight,
                                         symbol: viewModel.weightUnit,
                                         keyboardType: .decimalPad)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                    Divider()
                    ValidationErrorRow(errorMessage: Localization.getErrorMessage(for: viewModel.emptyPackageWeight))
                        .background(Color(.listBackground).ignoresSafeArea(.container, edges: .horizontal))
                        .padding(.horizontal, insets: safeAreaInsets)
                        .renderedIf(!viewModel.isWeightValidated)
                    ListHeaderView(text: Localization.weightFooter, alignment: .left)
                        .padding(.horizontal, insets: safeAreaInsets)
                }
        }
        .background(Color(.listBackground))
        .ignoresSafeArea(.container, edges: .horizontal)
    }
}

private extension ShippingLabelCustomPackageForm {
    enum Localization {
        static let customPackageHeader = NSLocalizedString(
            "Set up the package you'll be using to ship your products. We'll save it for future orders.",
            comment: "Header text on Add New Custom Package screen in Shipping Label flow")
        static let packageTypeLabel = NSLocalizedString(
            "Package Type",
            comment: "Title for the row to select the package type (box or envelope) on the Add New Custom Package screen in Shipping Label flow")
        static let packageTypePlaceholder = NSLocalizedString(
            "Select Type",
            comment: "Placeholder for the row to select the package type (box or envelope) on the Add New Custom Package screen in Shipping Label flow")
        static let packageNameLabel = NSLocalizedString(
            "Package Name",
            comment: "Title for the row to enter the package name on the Add New Custom Package screen in Shipping Label flow")
        static let packageNamePlaceholder = NSLocalizedString(
            "Enter Name",
            comment: "Placeholder for the row to enter the package name on the Add New Custom Package screen in Shipping Label flow")
        static let lengthLabel = NSLocalizedString(
            "Length",
            comment: "Title for the row to enter the package length on the Add New Custom Package screen in Shipping Label flow")
        static let widthLabel = NSLocalizedString(
            "Width",
            comment: "Title for the row to enter the package width on the Add New Custom Package screen in Shipping Label flow")
        static let heightLabel = NSLocalizedString(
            "Height",
            comment: "Title for the row to enter the package height on the Add New Custom Package screen in Shipping Label flow")
        static let emptyPackageWeightLabel = NSLocalizedString(
            "Empty Package Weight",
            comment: "Title for the row to enter the empty package weight on the Add New Custom Package screen in Shipping Label flow")
        static let weightFooter = NSLocalizedString(
            "Weight of empty package",
            comment: "Footer text for the empty package weight on the Add New Custom Package screen in Shipping Label flow")
        static func getErrorMessage(for input: String) -> String {
            if input.isEmpty {
                return inputMissingError
            } else {
                return inputInvalidError
            }
        }
        static let inputMissingError = NSLocalizedString(
            "This field is required",
            comment: "Error for missing package details on the Add New Custom Package screen in Shipping Label flow")
        static let inputInvalidError = NSLocalizedString(
            "Invalid value",
            comment: "Error for invalid package details on the Add New Custom Package screen in Shipping Label flow")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
    }
}

struct ShippingLabelAddCustomPackage_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelCustomPackageFormViewModel()

        ShippingLabelCustomPackageForm(viewModel: viewModel, safeAreaInsets: .zero)
            .previewLayout(.sizeThatFits)
    }
}
