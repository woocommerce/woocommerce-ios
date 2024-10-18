import SwiftUI

struct WooShippingServiceCardView: View {
    let carrierLogo: UIImage?
    let title: String
    let rate: String
    let daysToDelivery: String
    let extraInfo: String

    let trackingLabel: String?
    let insuranceLabel: String?
    let freePickupLabel: String?
    let signatureRequiredLabel: String?
    let adultSignatureRequiredLabel: String?

    @State var isSelected: Bool = false

    @State private var signatureSelection: SignatureSelection = .none

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let carrierLogo {
                Image(uiImage: carrierLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
            }
            VStack(alignment: .leading) {
                AdaptiveStack {
                    Text(title)
                    Spacer()
                    Text(rate)
                        .bold()
                }
                if isSelected {
                    VStack(alignment: .leading) {
                        Text(daysToDelivery)
                            .bold()
                            .font(.footnote)
                        Group {
                            VStack(alignment: .leading, spacing: 0) {
                                if let trackingLabel {
                                    HStack {
                                        checkmark
                                        Text(trackingLabel)
                                    }
                                }
                                if let insuranceLabel {
                                    HStack {
                                        checkmark
                                        Text(insuranceLabel)
                                    }
                                }
                                if let freePickupLabel {
                                    HStack {
                                        checkmark
                                        Text(freePickupLabel)
                                    }
                                }
                            }
                            if let signatureRequiredLabel {
                                HStack {
                                    selectionCircle(selected: signatureSelection == .signatureRequired)
                                    Text(signatureRequiredLabel)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if signatureSelection == .signatureRequired {
                                        signatureSelection = .none
                                    } else {
                                        signatureSelection = .signatureRequired
                                    }
                                }
                            }
                            if let adultSignatureRequiredLabel {
                                HStack {
                                    selectionCircle(selected: signatureSelection == .adultSignatureRequired)
                                    Text(adultSignatureRequiredLabel)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if signatureSelection == .adultSignatureRequired {
                                        signatureSelection = .none
                                    } else {
                                        signatureSelection = .adultSignatureRequired
                                    }
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                } else {
                    Group {
                        Text(daysToDelivery).bold() + Text("  •  ") + Text(extraInfo)
                    }
                    .font(.footnote)
                }
            }
        }
        .padding(16)
        .if(isSelected) { card in
            card.background(Color(.wooCommercePurple(.shade0)))
        }
        .roundedBorder(cornerRadius: 8, lineColor: isSelected ? Color(.primary) : Color(.separator), lineWidth: isSelected ? 2 : 1)
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

    private enum SignatureSelection {
        case none
        case signatureRequired
        case adultSignatureRequired
    }
}

#Preview {
    WooShippingServiceCardView(carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                               title: "USPS - Media Mail",
                               rate: "$7.63",
                               daysToDelivery: "7 business days",
                               extraInfo: "Includes tracking, insurance (up to $100.00), free pickup",
                               trackingLabel: nil,
                               insuranceLabel: nil,
                               freePickupLabel: nil,
                               signatureRequiredLabel: nil,
                               adultSignatureRequiredLabel: nil)
}

#Preview {
    WooShippingServiceCardView(carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                               title: "USPS - Media Mail",
                               rate: "$7.63",
                               daysToDelivery: "7 business days",
                               extraInfo: "Includes tracking, insurance (up to $100.00), free pickup",
                               trackingLabel: "Tracking",
                               insuranceLabel: "Insurance (up to $100.00)",
                               freePickupLabel: "Free pickup",
                               signatureRequiredLabel: "Signature Required (+$3.70)",
                               adultSignatureRequiredLabel: "Adult Signature Required (+$9.35)",
                               isSelected: true)
}
