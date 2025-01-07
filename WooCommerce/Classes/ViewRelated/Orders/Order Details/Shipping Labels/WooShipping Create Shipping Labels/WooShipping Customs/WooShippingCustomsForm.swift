import SwiftUI
import WooFoundation
import Yosemite

struct WooShippingCustomsForm: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: WooShippingCustomsFormViewModel
    @State private var isShowingITNInfoWebView = false

    private var contentTypeSelectionView: some View {
        Menu {
            // show selection
            ForEach(WooShippingContentType.allCases, id: \.self) { option in
                Button {
                } label: {
                    Text(option.name)
                        .bodyStyle()
                    if viewModel.contentType == option {
                        Image(uiImage: .checkmarkStyledImage)
                    }
                }
            }
        } label: {
            HStack {
                Text(viewModel.contentType.name)
                    .bodyStyle()
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding()
        }
        .roundedBorder(cornerRadius: Constants.borderCornerRadius, lineColor: Color(.separator), lineWidth: Constants.borderWidth)
    }

    private var restrictionTypeSelectionView: some View {
        Menu {
            // show selection
            ForEach(WooShippingRestrictionType.allCases, id: \.self) { option in
                Button {
                } label: {
                    Text(option.name)
                        .bodyStyle()
                    if viewModel.restrictionType == option {
                        Image(uiImage: .checkmarkStyledImage)
                    }
                }
            }
        } label: {
            HStack {
                Text(viewModel.restrictionType.name)
                    .bodyStyle()
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding()
        }
        .roundedBorder(cornerRadius: Constants.borderCornerRadius, lineColor: Color(.separator), lineWidth: Constants.borderWidth)
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                                HStack {
                                    Text(Localization.contentType)
                                        .font(.subheadline)
                                    Spacer()
                                }

                                contentTypeSelectionView
                                    .padding(.bottom, Constants.defaultVerticalSpacing)

                                HStack {
                                    Text(Localization.restrictionType)
                                        .font(.subheadline)
                                    Spacer()
                                }

                                restrictionTypeSelectionView
                                    .padding(.bottom, Constants.defaultVerticalSpacing)

                                HStack {
                                    Text(Localization.internationalTransactionNumber)
                                        .font(.subheadline)
                                    Spacer()
                                }

                                TextField("", text: $viewModel.internationalTransactionNumber)
                                    .padding(Constants.borderPadding)
                                    .roundedBorder(cornerRadius: Constants.borderCornerRadius, lineColor: Color(.separator), lineWidth: Constants.borderWidth)

                                Button {
                                    isShowingITNInfoWebView = true
                                } label: {
                                    HStack(alignment: .top, spacing: Constants.intoButtonHorizontalSpacing) {
                                        Image(systemName: "info.circle")
                                        Text(Localization.infoText)
                                    }
                                    .foregroundColor(Color(.wooCommercePurple(.shade60)))
                                    .footnoteStyle()
                                    .padding(.bottom, Constants.bottomButtonPadding)
                                }

                                Toggle(isOn: $viewModel.returnToSenderIfNotDelivered) {
                                    Text(Localization.returnToSenderMessage)
                                        .font(.subheadline)
                                }
                                .tint(Color.accentColor)
                                .padding(.bottom, Constants.returnToSenderRowBottomPadding)

                                Text(Localization.productDetailsTitle)
                                    .tertiaryTitleStyle()
                                    .padding(.bottom, Constants.defaultVerticalSpacing)

                                // Dummy data
                                WooShippingCustomsItem(viewModel: WooShippingCustomsItemViewModel(
                                    title: "Little Nap Brazil 250g",
                                    description: "Coffee Beans",
                                    hsTariffNumber: "HS 14-1",
                                    valuePerUnit: "",
                                    weightPerUnit: "",
                                    originCountry: WooShippingCustomsCountry(code: "US", name: "United States"))
                                )
                            }
                            .padding()
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(action: {
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Text(Localization.cancel)
                                    })
                                }
                            }
                            .navigationTitle(Localization.customs)
                            .navigationBarTitleDisplayMode(.inline)

                            Spacer()
                        }
                        .navigationViewStyle(.stack)
                        .safariSheet(isPresented: $isShowingITNInfoWebView, url: viewModel.itnInfoURL)
                    }

                    Spacer()

                    Divider()

                    Button {
                        // TODO: Save values
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text(viewModel.informationIsMissing ? Localization.addMissingInformationButtonTitle : Localization.saveCustomsDetailsButtonTitle)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.informationIsMissing)
                    .padding(Constants.bottomButtonPadding)
                }
            }

        }
    }
}

extension WooShippingCustomsForm {
    enum Localization {
        static let cancel = NSLocalizedString("wooShipping.customs.cancel",
                                              value: "Cancel",
                                              comment: "Cancel button in navigation bar to dismiss the screen")
        static let customs = NSLocalizedString("wooShipping.customs.title",
                                                  value: "Customs",
                                                  comment: "Title for the Customs screen")
        static let contentType = NSLocalizedString("wooShipping.customs.contentType",
                                                   value: "Content Type",
                                                   comment: "Title for the Content Type menu in the Shipping Customs Form")
        static let restrictionType = NSLocalizedString("wooShipping.customs.restrictionType",
                                                   value: "Restriction Type",
                                                   comment: "Title for the Restriction Type menu in the Shipping Customs Form")
        static let internationalTransactionNumber = NSLocalizedString("wooShipping.customs.internationalTransactionNumber",
                                                   value: "International Transaction Number",
                                                   comment: "Title for the Internaction Transaction Number in the Shipping Customs Form")
        static let infoText = NSLocalizedString("wooShipping.customs.internationalTransactionNumber.infoText",
                                                value: "More info about ITN",
                                                comment: "Explanatory text for the international transaction number in customs")
        static let returnToSenderMessage = NSLocalizedString("wooShipping.customs.returnToSenderMessage",
                                                              value: "Return to sender if package is not able to be delivered",
                                                              comment: "Info label for a toggle to return the package to a sender if necessary toggle")
        static let addMissingInformationButtonTitle = NSLocalizedString("wooShipping.customs.addMissingInformationButtonTitle",
                                                              value: "Add Missing Information",
                                                              comment: "Customs button title when it's disabled and there's still info to add")
        static let saveCustomsDetailsButtonTitle = NSLocalizedString("wooShipping.customs.saveCustomsDetails",
                                                              value: "Save Customs Details",
                                                              comment: "Customs button title when it's enabled and there's no info to add")
        static let productDetailsTitle = NSLocalizedString("wooShipping.customs.productDetails",
                                                           value: "Product Details",
                                                           comment: "Product Details Section title")
    }

}

extension WooShippingCustomsForm {
    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 8.0
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let borderPadding: CGFloat = 16
        static let intoButtonHorizontalSpacing: CGFloat = 8
        static let bottomButtonPadding: CGFloat = 16.0
        static let returnToSenderRowBottomPadding: CGFloat = 32.0
    }
}
