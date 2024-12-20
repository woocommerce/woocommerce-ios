import SwiftUI
import struct Yosemite.ShippingLabelAddress

/// View to display a list of origin addresses for the Woo Shipping extension.
struct WooShippingOriginAddressListView: View {
    private var originAddresses: [WooShippingOriginAddress]

    @State private var selectedAddressID: String

    init(originAddresses: [WooShippingOriginAddress],
         selectedAddressID: String) {
        self.originAddresses = originAddresses
        self._selectedAddressID = State(initialValue: selectedAddressID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                Text(Localization.shipFrom)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, Constants.verticalSpacing)
                ForEach(originAddresses) { address in
                    addressView(address)
                        .onTapGesture {
                            selectedAddressID = address.id
                        }
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func addressView(_ address: WooShippingOriginAddress) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(address.name)
                        .bold()
                    if address.isDefault {
                        Text(Localization.defaultAddress)
                            .bold()
                    }
                }
                Text(address.address)
            }
            Spacer()
            PencilEditButton {
                // TODO: Edit origin address
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding()
        .if(address.id == selectedAddressID) {
            $0.background(Color(.wooCommercePurple(.shade0)), ignoresSafeAreaEdges: .vertical)
        }
        .roundedBorder(cornerRadius: Constants.cornerRadius,
                       lineColor: Color(address.id == selectedAddressID ? .wooCommercePurple(.shade60) : .separator),
                       lineWidth: address.id == selectedAddressID ? 2 : 0.5)
    }

    struct WooShippingOriginAddress: Identifiable, Hashable {
        let id: String

        /// Merchant or company name
        let name: String

        /// Full address
        let address: String

        /// If the address is the default one
        let isDefault: Bool
    }
}

private extension WooShippingOriginAddressListView {
    enum Constants {
        static let verticalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }
}

private extension WooShippingOriginAddressListView {
    enum Localization {
        static let shipFrom = NSLocalizedString("wooShipping.originAddresses.shipFrom",
                                                value: "Ship From",
                                                comment: "Heading for the list of origin addresses to choose from on the shipping label creation screen")
            .localizedUppercase
        static let defaultAddress = NSLocalizedString("wooShipping.originAddresses.defaultAddress",
                                                      value: "(default)",
                                                      comment: "Indicates that the address is the default origin address  on the shipping label creation screen")
    }
}

#Preview {
    WooShippingOriginAddressListView(originAddresses: [.init(id: "address_1",
                                                             name: "HEADQUARTERS",
                                                             address: "417 MONTGOMERY ST, SAN FRANCISCO, CA 94104-1129, US",
                                                             isDefault: true),
                                                       .init(id: "address_2",
                                                             name: "WAREHOUSE",
                                                             address: "15 ALGONKIN ST, TICONDEROGA, NY 12883-1487, US",
                                                             isDefault: false)],
                                     selectedAddressID: "address_1")
}

#Preview("Bottom sheet presentation") {
    Text("Background view")
        .sheet(isPresented: .constant(true)) {
            WooShippingOriginAddressListView(originAddresses: [.init(id: "address_1",
                                                                     name: "HEADQUARTERS",
                                                                     address: "417 MONTGOMERY ST, SAN FRANCISCO, CA 94104-1129, US",
                                                                     isDefault: true),
                                                               .init(id: "address_2",
                                                                     name: "WAREHOUSE",
                                                                     address: "15 ALGONKIN ST, TICONDEROGA, NY 12883-1487, US",
                                                                     isDefault: false)],
                                             selectedAddressID: "address_1")
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}
