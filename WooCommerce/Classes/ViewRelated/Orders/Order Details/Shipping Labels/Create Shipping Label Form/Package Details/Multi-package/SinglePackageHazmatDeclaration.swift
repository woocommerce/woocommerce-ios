import SwiftUI

struct SinglePackageHazmatDeclaration: View {
    @ObservedObject private var viewModel: ShippingLabelSinglePackageViewModel
    @State private var isShowingHazmatSelection = false
    @State private var destinationURL: URL?

    private let safeAreaInsets: EdgeInsets

    init(safeAreaInsets: EdgeInsets,
         viewModel: ShippingLabelSinglePackageViewModel) {
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            VStack {
                Divider()

                TitleAndToggleRow(title: Localization.containsHazmatMaterials, isOn: $viewModel.containsHazmatMaterials)
                    .padding(.horizontal, insets: safeAreaInsets)
                    .padding(.horizontal, Constants.horizontalPadding)

                VStack {
                    Divider()
                        .padding(.leading, Constants.horizontalPadding)

                    Button(action: {
                        isShowingHazmatSelection.toggle()
                        viewModel.hazmatCategorySelectorOpened()
                    }, label: {
                        HStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text(Localization.hazmatCategoryTitle)
                                    .bodyStyle()
                                Text(viewModel.selectedHazmatCategory.localizedName)
                                    .calloutStyle()
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            DisclosureIndicator()
                                .frame(alignment: .trailing)
                        }
                        .padding(.horizontal, Constants.horizontalPadding)
                        .sheet(isPresented: $isShowingHazmatSelection) {
                            NavigationStack {
                                SingleSelectionList(title: Localization.selectHazmatCategory,
                                                    items: viewModel.selectableHazmatCategories,
                                                    contentKeyPath: \.localizedName,
                                                    selected: $viewModel.selectedHazmatCategory)
                            }
                            .wooNavigationBarStyle()
                        }
                    })

                    Divider()
                        .padding(.leading, Constants.horizontalPadding)

                    createHazmatInstructionsView()
                }
                .renderedIf(viewModel.containsHazmatMaterials)
                .padding(.horizontal, insets: safeAreaInsets)

                Divider()
            }
            .background(Color(.listForeground(modal: false)))

            Text(Localization.hazmatTooltip)
                .renderedIf(!viewModel.containsHazmatMaterials)
                .padding(.horizontal, insets: safeAreaInsets)
                .padding(.leading, Constants.horizontalPadding)
                .calloutStyle()
        }
        .renderedIf(viewModel.isHazmatShippingEnabled)
    }

    private func createHazmatInstructionsView() -> some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(Localization.hazmatInstructionsFirstSection)
                .calloutStyle()

            Spacer()
            createText(withLink: Localization.hazmatInstructionsSecondSectionLink,
                       url: WooConstants.URLs.uspsInstructions.asURL(),
                       content: Localization.hazmatInstructionsSecondSection)

            Spacer()
            createText(withLink: Localization.hazmatInstructionsThirdSectionLink,
                       url: WooConstants.URLs.uspsSearchTool.asURL(),
                       content: Localization.hazmatInstructionsThirdSection)

            Spacer()
            createText(withLink: Localization.hazmatInstructionsFourthSectionLink,
                       url: WooConstants.URLs.dhlExpressInstructions.asURL(),
                       content: Localization.hazmatInstructionsFourthSection)

            Spacer()
        }
        .padding(.leading, Constants.horizontalPadding)
        .padding(.trailing, Constants.longTextTrailingPadding)
    }

    private func createText(withLink linkText: String, url: URL, content: String) -> some View {
        var attributedText = AttributedString(.init(format: content, linkText))
        if let range = attributedText.range(of: linkText) {
            attributedText[range].mergeAttributes(AttributeContainer().link(url))
        }
        return Text(attributedText)
            .calloutStyle()
            .environment(\.openURL, OpenURLAction { url in
                destinationURL = url
                return .handled
            })
            .safariSheet(url: $destinationURL)
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
                                                                       "USPS® at %1$@.",
                                                                       comment: "Instructions for hazardous package shipping. The %1$@ is a tappable link" +
                                                                       "that will direct the user to a website")
        static let hazmatInstructionsThirdSection = NSLocalizedString("Determine your product's mailability using the %1$@.",
                                                                      comment: "Instructions for hazardous package shipping. The %1$@ is a tappable link " +
                                                                      "that will direct the user to a website")
        static let hazmatInstructionsFourthSection = NSLocalizedString("WooCommerce Shipping does not currently support HAZMAT shipments "
                                                                       + "through %1$@.",
                                                                       comment: "Instructions for hazardous package shipping. The %1$@ is a tappable link" +
                                                                       "that will direct the user to a website")
        static let hazmatInstructionsSecondSectionLink = NSLocalizedString("www.usps.com/hazmat", comment: "A clickable text link that will" +
                                                                           "redirect the user to a website")
        static let hazmatInstructionsThirdSectionLink = NSLocalizedString("USPS HAZMAT Search Tool", comment: "A clickable text link that will" +
                                                                          "redirect the user to a website")
        static let hazmatInstructionsFourthSectionLink = NSLocalizedString("DHL Express", comment: "A clickable text link that will" +
                                                                           "redirect the user to a website")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let longTextTrailingPadding: CGFloat = 12
    }
}

#if DEBUG
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
                                                            hazmatCategory: .none,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in })
        SinglePackageHazmatDeclaration(safeAreaInsets: .zero, viewModel: viewModel)
    }
}
#endif
