import SwiftUI

struct WooShippingPackageOptionView: View {
    enum Constants {
        static let verticalSpacing: CGFloat = 4.0
        static let textContentLeadingPadding: CGFloat = 4.0
        static let contentPadding: CGFloat = 16.0
    }

    var isSelected: Bool?
    var package: WooShippingPackageDataRepresentable
    var showTopDivider: Bool
    var showSource: Bool
    var tapAction: () -> Void
    var starAction: (() -> Void)?
    var starred: Bool?

    @Environment(\.shippingDimensionsUnit) private var dimensionsUnit
    @Environment(\.shippingWeightUnit) private var weightUnit

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                if let isSelected {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? Color(.withColorStudio(.wooCommercePurple, shade: .shade60)) : .gray)
                        .font(.title)
                }
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    if showSource {
                        Text(package.source.userFriendlyDescription)
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    Text(package.name)
                        .bodyStyle()
                    HStack {
                        Text(package.dimensionsDescription(unit: dimensionsUnit))
                        if let weight = package.weightDescription(unit: weightUnit) {
                            Text("•")
                            Text(weight)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(.text))
                }
                .padding(.leading, Constants.textContentLeadingPadding)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                tapAction()
            }
            .padding(Constants.contentPadding)
            if let starAction, let starred {
                VStack {
                    Image(systemName: starred ? "star.fill": "star")
                        .foregroundStyle(.secondary)
                        .padding(Constants.contentPadding)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    starAction()
                }
            }
        }
    }
}
