import SwiftUI

struct WooShippingCustomsForm: View {
    @Environment(\.presentationMode) var presentationMode
    let contentType: WooShippingContentType = .merchandise
    let restrictionType: WooShippingRestrictionType = .none

    private var contentTypeSelectionView: some View {
        Menu {
            // show selection
            ForEach(WooShippingContentType.allCases, id: \.self) { option in
                Button {
                } label: {
                    Text(option.name)
                        .bodyStyle()
                    if contentType == option {
                        Image(uiImage: .checkmarkStyledImage)
                    }
                }
            }
        } label: {
            HStack {
                Text(contentType.name)
                    .bodyStyle()
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding()
        }
        .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
    }

    private var restrictionTypeSelectionView: some View {
        Menu {
            // show selection
            ForEach(WooShippingRestrictionType.allCases, id: \.self) { option in
                Button {
                } label: {
                    Text(option.name)
                        .bodyStyle()
                    if restrictionType == option {
                        Image(uiImage: .checkmarkStyledImage)
                    }
                }
            }
        } label: {
            HStack {
                Text(restrictionType.name)
                    .bodyStyle()
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding()
        }
        .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
    }

    var body: some View {
        NavigationView {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                        VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                            HStack {
                                Text(Localization.contentType)
                                    .font(.subheadline)
                                Spacer()
                            }

                            contentTypeSelectionView

                            HStack {
                                Text(Localization.restrictionType)
                                    .font(.subheadline)
                                Spacer()
                            }

                            restrictionTypeSelectionView
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
                                                   comment: "Title for the Content Type menu in the Shipping Customs Menu")
        static let restrictionType = NSLocalizedString("wooShipping.customs.restrictionType",
                                                   value: "Restriction Type",
                                                   comment: "Title for the Restriction Type menu in the Shipping Customs Menu")
    }

}

extension WooShippingCustomsForm {
    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 16.0
    }
}

struct WooShippingCustomsFormOld: View {
    @State private var contentType: String = "Merchandise"
    @State private var restrictionType: String = "None"
    @State private var internationalTransactionNumber: String = ""
    @State private var returnToSender: Bool = false
    @State private var productDetails: [ProductDetail] = [
        ProductDetail(name: "Little Nap Brazil 250g", type: "Coffee beans", origin: "Japan", weight: 0.3, price: 20.0),
        ProductDetail(name: "Partners Brooklyn 250g", type: "", origin: "", weight: 0.0, price: 0.0)
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customs")) {
                    Picker("Content Type", selection: $contentType) {
                        Text("Merchandise").tag("Merchandise")
                        // Add more content types as needed
                    }
                    Picker("Restriction Type", selection: $restrictionType) {
                        Text("None").tag("None")
                        // Add more restriction types as needed
                    }
                    TextField("International Transaction Number", text: $internationalTransactionNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: false))
                    Toggle("Return to sender if package is not able to be delivered", isOn: $returnToSender)
                }

                //                Section(header: Text("Product Details")) {
                //                    ForEach($productDetails, id: \.$id) { $product in
                //                        VStack(alignment: .leading) {
                //                            Text(product.name)
                //                                .font(.headline)
                //                            Text("Type: \(product.type)")
                //                            Text("Origin: \(product.origin)")
                //                            Text("Weight: \(product.weight, specifier: "%.2f") kg")
                //                            Text("Price: $\(product.price, specifier: "%.2f")")
                //                        }
                //                        .padding(.vertical, 5)
                //                    }
            }

            Button(action: {
                // Action for adding missing information
            }) {
                Text("Add Missing Information")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Customs Form")
    }
}


struct ProductDetail: Identifiable {
    let id = UUID()
    var name: String
    var type: String
    var origin: String
    var weight: Double
    var price: Double
}

enum WooShippingContentType: String, CaseIterable {
    case merchandise
    case documents
    case gift
    case sample
    case other
    var name: String {
        switch self {
        case .merchandise:
            return Localization.merchandise
        case .documents:
            return Localization.documents
        case .gift:
            return Localization.gift
        case .sample:
            return Localization.sample
        case .other:
            return Localization.other

        }
    }
}

extension WooShippingContentType {
    enum Localization {
        static let merchandise = NSLocalizedString("wooShipping.customs.contentType.merchandise",
                                                   value: "Merchandise",
                                                   comment: "Info label for shipping content type merchandise")
        static let documents = NSLocalizedString("wooShipping.customs.contentType.documents",
                                                   value: "Documents",
                                                   comment: "Info label for shipping content type merchandise")
        static let gift = NSLocalizedString("wooShipping.customs.contentType.gift",
                                                   value: "Gift",
                                                   comment: "Info label for shipping content type merchandise")
        static let sample = NSLocalizedString("wooShipping.customs.contentType.sample",
                                                   value: "Sample",
                                                   comment: "Info label for shipping content type merchandise")
        static let other = NSLocalizedString("wooShipping.customs.contentType.other",
                                                   value: "Other",
                                                   comment: "Info label for shipping content type merchandise")
    }
}

enum WooShippingRestrictionType: String, CaseIterable {
    case none
    case quarantine
    case sanitary
    case other
    var name: String {
        switch self {
        case .none:
            return Localization.none
        case .quarantine:
            return Localization.quarantine
        case .sanitary:
            return Localization.sanitary
        case .other:
            return Localization.other

        }
    }
}

extension WooShippingRestrictionType {
    enum Localization {
        static let none = NSLocalizedString("wooShipping.customs.restrictionType.none",
                                                   value: "None",
                                                   comment: "Info label for shipping restriction type none")
        static let quarantine = NSLocalizedString("wooShipping.customs.restrictionType.quarantine",
                                                   value: "Quarantine",
                                                   comment: "Info label for shipping restriction type quarantine")
        static let sanitary = NSLocalizedString("wooShipping.customs.restrictionType.sanitary",
                                                   value: "Sanitary",
                                                   comment: "Info label for shipping restriction type sanitary")
        static let other = NSLocalizedString("wooShipping.customs.restrictionType.other",
                                                   value: "Other",
                                                   comment: "Info label for shipping restriction type other")
    }
}
