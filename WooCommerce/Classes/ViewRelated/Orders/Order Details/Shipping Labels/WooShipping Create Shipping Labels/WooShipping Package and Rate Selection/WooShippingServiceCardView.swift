import SwiftUI

/// Card to display the rate details for a shipping service with the Woo Shipping extension.
struct WooShippingServiceCardView: View {
    @ObservedObject var viewModel: WooShippingServiceCardViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let carrierLogo = viewModel.carrierLogo {
                Image(uiImage: carrierLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
            }
            VStack(alignment: .leading) {
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(viewModel.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(viewModel.rateLabel)
                        .bold()
                }
                if viewModel.selected {
                    VStack(alignment: .leading) {
                        if let daysToDelivery = viewModel.daysToDeliveryLabel {
                            Text(daysToDelivery)
                                .bold()
                                .font(.footnote)
                        }
                        Group {
                            VStack(alignment: .leading, spacing: 0) {
                                if let tracking = viewModel.trackingLabel {
                                    HStack {
                                        checkmark
                                        Text(tracking)
                                    }
                                }
                                if let insurance = viewModel.insuranceLabel {
                                    HStack {
                                        checkmark
                                        Text(insurance)
                                    }
                                }
                                if let freePickup = viewModel.freePickupLabel {
                                    HStack {
                                        checkmark
                                        Text(freePickup)
                                    }
                                }
                            }
                            if let signatureRequired = viewModel.signatureRequiredLabel {
                                HStack {
                                    selectionCircle(selected: viewModel.signatureRequirement == .signatureRequired)
                                    Text(signatureRequired)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.handleTap(on: .signatureRequired)
                                }
                            }
                            if let adultSignatureRequired = viewModel.adultSignatureRequiredLabel {
                                HStack {
                                    selectionCircle(selected: viewModel.signatureRequirement == .adultSignatureRequired)
                                    Text(adultSignatureRequired)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.handleTap(on: .adultSignatureRequired)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                } else {
                    Group {
                        if let daysToDelivery = viewModel.daysToDeliveryLabel,
                           let extraInfo = viewModel.extraInfoLabel {
                            Text(daysToDelivery).bold() + Text("  •  ") + Text(extraInfo)
                        } else if let daysToDelivery = viewModel.daysToDeliveryLabel {
                            Text(daysToDelivery).bold()
                        } else if let extraInfo = viewModel.extraInfoLabel {
                            Text(extraInfo)
                        }
                    }
                    .font(.footnote)
                }
            }
        }
        .padding(16)
        .if(viewModel.selected) { card in
            card.background { Color(.wooCommercePurple(.shade0)) }
        }
        .roundedBorder(cornerRadius: 8,
                       lineColor: viewModel.selected ? Color(.primary) : Color(.separator),
                       lineWidth: viewModel.selected ? 2 : 1)
    }

    @ViewBuilder
    private var checkmark: some View {
        Image(uiImage: .checkmarkStyledImage)
            .resizable()
            .scaledToFit()
            .frame(width: 24)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func selectionCircle(selected: Bool) -> some View {
        if selected {
            Image(uiImage: .checkCircleImage.withRenderingMode(.alwaysTemplate))
                .foregroundStyle(Color(.primary))
        } else {
            Image(uiImage: .checkEmptyCircleImage)
        }
    }
}

#Preview {
    WooShippingServiceCardView(viewModel: WooShippingServiceCardViewModel(carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                                                                          title: "USPS - Media Mail",
                                                                          rateLabel: "$7.63",
                                                                          daysToDeliveryLabel: "7 business days",
                                                                          extraInfoLabel: "Includes tracking, insurance (up to $100.00), free pickup",
                                                                          hasTracking: true,
                                                                          insuranceLabel: nil,
                                                                          hasFreePickup: true,
                                                                          signatureRequiredLabel: nil,
                                                                          adultSignatureRequiredLabel: nil))
}

#Preview {
    WooShippingServiceCardView(viewModel: WooShippingServiceCardViewModel(selected: true,
                                                                          signatureRequirement: .signatureRequired,
                                                                          carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                                                                          title: "USPS - Media Mail",
                                                                          rateLabel: "$7.63",
                                                                          daysToDeliveryLabel: "7 business days",
                                                                          extraInfoLabel: "Includes tracking, insurance (up to $100.00), free pickup",
                                                                          hasTracking: true,
                                                                          insuranceLabel: "Insurance (up to $100.00)",
                                                                          hasFreePickup: true,
                                                                          signatureRequiredLabel: "Signature Required (+$3.70)",
                                                                          adultSignatureRequiredLabel: "Adult Signature Required (+$9.35)"))
}
