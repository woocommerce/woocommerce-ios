import SwiftUI

struct SinglePackageHazmatDeclaration: View {
    @ObservedObject private var viewModel: ShippingLabelSinglePackageViewModel
    @State private var isShowingHazmatSelection = false

    private let safeAreaInsets: EdgeInsets

    init(safeAreaInsets: EdgeInsets,
         viewModel: ShippingLabelSinglePackageViewModel) {
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Divider()

                TitleAndToggleRow(title: Localization.containsHazmatMaterials, isOn: $viewModel.containsHazmatMaterials)
                    .padding(.horizontal, Constants.horizontalPadding)

                VStack {
                    Divider()
                        .padding(.horizontal, insets: safeAreaInsets)
                        .padding(.leading, Constants.horizontalPadding)

                    TitleAndValueRow(title: Localization.hazmatCategoryTitle, value: .placeholder(Localization.selectHazmatCategory)) {
                        isShowingHazmatSelection.toggle()
                    }

                    Divider()
                        .padding(.horizontal, insets: safeAreaInsets)
                        .padding(.leading, Constants.horizontalPadding)

                    createHazmatInstructionsView()

                }
                .renderedIf(viewModel.containsHazmatMaterials)

                Divider()
            }
            .background(Color(.listForeground(modal: false)))

            Text(Localization.hazmatTooltip)
                .renderedIf(!viewModel.containsHazmatMaterials)
                .padding(.leading, Constants.horizontalPadding)
                .calloutStyle()
        }
        .renderedIf(viewModel.isHazmatShippingEnabled)
    }

    func createHazmatInstructionsView() -> some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(Localization.hazmatInstructionsFirstSection)
                .calloutStyle()

            Spacer()
            Text(Localization.hazmatInstructionsSecondSection)
                .calloutStyle()

            Spacer()
            Text(Localization.hazmatInstructionsThirdSection)
                .calloutStyle()

            Spacer()
            Text(Localization.hazmatInstructionsFourthSection)
                .calloutStyle()

            Spacer()
        }
        .padding(.leading, Constants.horizontalPadding)
        .padding(.trailing, Constants.longTextTrailingPadding)
    }
}

private extension SinglePackageHazmatDeclaration {
    enum Localization {
        static let containsHazmatMaterials = NSLocalizedString("Contains Hazardous Materials",
                                                               comment: "Toggle to declare when a package contains hazardous materials")
        static let hazmatTooltip = NSLocalizedString("Select this if your package contains dangerous goods or hazardous materials",
                                                     comment: "Tooltip below the hazmat toggle detailing when to select it")
        static let hazmatCategoryTitle = NSLocalizedString("Hazardous material category",
                                                           comment: "Button title for the hazmat material category selection")
        static let selectHazmatCategory = NSLocalizedString("Select a category",
                                                            comment: "Hazmat category button tooltip asking to select a category")
        static let hazmatInstructionsFirstSection = NSLocalizedString("Potentially hazardous material includes items such as batteries, " +
                                                                      "dry ice, flammable liquids, aerosols, ammunition, fireworks, nail " +
                                                                      "polish, perfume, paint, solvents, and more. Hazardous items must " +
                                                                      "ship in separate packages.",
                                                                      comment: "Instructions for hazardous package shipping")
        static let hazmatInstructionsSecondSection = NSLocalizedString("Learn how to securely package, label, and ship HAZMAT through " +
                                                                       "USPS® at www.usps.com/hazmat.",
                                                                       comment: "Instructions for hazardous package shipping")
        static let hazmatInstructionsThirdSection = NSLocalizedString("Determine your product's mailability using the USPS HAZMAT Search Tool.",
                                                                      comment: "Instructions for hazardous package shipping")
        static let hazmatInstructionsFourthSection = NSLocalizedString("WooCommerce Shipping does not currently support HAZMAT shipments "
                                                                       + "through DHL Express.",
                                                                       comment: "Instructions for hazardous package shipping")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let longTextTrailingPadding: CGFloat = 12
    }
}

struct HazmatDeclaration_Previews: PreviewProvider {
    static var previews: some View {
        let order = ShippingLabelSampleData.sampleOrder()
        let packageResponse = ShippingLabelSampleData.samplePackageDetails()
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                            orderItems: [],
                                                            packagesResponse: packageResponse,
                                                            selectedPackageID: "Box 1",
                                                            totalWeight: "",
                                                            isOriginalPackaging: false,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in })
        SinglePackageHazmatDeclaration(safeAreaInsets: .zero, viewModel: viewModel)
    }
}
