import SwiftUI

/// View to display a list of origin addresses for the Woo Shipping extension.
struct WooShippingOriginAddressListView: View {
    @ObservedObject var viewModel: WooShippingOriginAddressListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            Text(Localization.shipFrom)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, Constants.verticalSpacing)
            List(viewModel.addresses) { address in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .firstTextBaseline) {
                            Text(address.fullNameWithCompany)
                                .bold()
                            if address.defaultAddress {
                                Text(Localization.defaultAddress)
                                    .bold()
                            }
                        }
                        if let formattedAddress = address.formattedPostalAddress {
                            Text(formattedAddress)
                        }
                    }
                    Spacer()
                    PencilEditButton {
                        // TODO: Edit origin address
                    }
                    .buttonStyle(TextButtonStyle())
                }
                .padding()
                .if(viewModel.isSelected(address)) {
                    $0.background(Color(.wooCommercePurple(.shade0)), ignoresSafeAreaEdges: .vertical)
                }
                .roundedBorder(cornerRadius: Constants.cornerRadius,
                               lineColor: Color(viewModel.isSelected(address) ? .wooCommercePurple(.shade60) : .separator),
                               lineWidth: viewModel.isSelected(address) ? 2 : 0.5)
                    .onTapGesture {
                        viewModel.select(address)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: Constants.verticalSpacing, trailing: 0))
            }
            .listStyle(.plain)
        }
        .padding()
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
    WooShippingOriginAddressListView(viewModel: .init(addresses: WooShippingOriginAddressListView.sampleAddresses(),
                                                      selectedAddressID: "1"))
}

#Preview("Bottom sheet presentation") {
    Text("Background view")
        .sheet(isPresented: .constant(true)) {
            WooShippingOriginAddressListView(viewModel: .init(addresses: WooShippingOriginAddressListView.sampleAddresses(),
                                                              selectedAddressID: "1"))
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
}
