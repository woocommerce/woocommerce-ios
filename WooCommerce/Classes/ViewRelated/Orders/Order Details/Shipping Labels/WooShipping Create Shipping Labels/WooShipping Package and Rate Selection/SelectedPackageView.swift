import SwiftUI

struct SelectedPackageView: View {
    let package: WooShippingPackageDataRepresentable
    let weightUnit: String
    @Binding var totalWeight: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.package)
                    .headlineStyle()
                Spacer()
                PencilEditButton {
                    // TODO: Edit selected package
                }
                .buttonStyle(TextButtonStyle())
            }
            PackageOptionView(package: package,
                              showTopDivider: false,
                              showSource: true,
                              tapAction: {})
            .roundedBorder(cornerRadius: Constants.cornerRadius, lineColor: Constants.lineColor, lineWidth: Constants.lineWidth)
            .padding(.bottom)
            shipmentWeight
        }
    }

    private var shipmentWeight: some View {
        VStack(alignment: .leading) {
            Text(Localization.totalWeight)
                .bodyStyle()
            HStack {
                TextField("", text: $totalWeight)
                    .keyboardType(.decimalPad)
                    .bodyStyle()
                Text(weightUnit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: Constants.cornerRadius, lineColor: Constants.lineColor, lineWidth: Constants.lineWidth)
        }
    }
}

private extension SelectedPackageView {
    enum Constants {
        static let cornerRadius: CGFloat = 8
        static let lineColor = Color(.separator)
        static let lineWidth: CGFloat = 0.5
    }

    enum Localization {
        static let package = NSLocalizedString("wooShipping.createLabels.package.title",
                                               value: "Package",
                                               comment: "Heading for the package section in the shipping label creation screen.")
        static let totalWeight = NSLocalizedString("wooShipping.createLabels.package.totalWeight",
                                                    value: "Total shipment weight (with package)",
                                                    comment: "Label for the total shipment weight input field in the shipping label creation screen.")
    }
}

#Preview {
    SelectedPackageView(package: WooShippingPackageData(name: "Small Flat Rate Box",
                                                        length: "12",
                                                        width: "6",
                                                        height: "6",
                                                        dimensionsUnit: "in",
                                                        weight: "4",
                                                        weightUnit: "oz",
                                                        source: .predefined(sourceTitle: "USPS Priority Mail Flat Rate Boxes", sourceID: "usps"),
                                                        packageType: "box"),
                        weightUnit: "oz",
                        totalWeight: .constant("6"))
}
