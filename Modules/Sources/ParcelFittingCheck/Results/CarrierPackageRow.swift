import SwiftUI

struct CarrierPackageRow: View {
    let carrier: ParcelPresetCarrier
    let package: ParcelPresetPackage
    let unit: UnitLength
    let isSelected: Bool
    let isStarred: Bool
    let onSelect: () -> Void
    let onToggleStar: (() -> Void)?

    var body: some View {
        HStack(spacing: Constants.outerSpacing) {
            Button(action: onSelect) {
                HStack(spacing: Constants.outerSpacing) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .gray)
                        .font(.title2)

                    carrierLogo

                    VStack(alignment: .leading, spacing: Constants.textSpacing) {
                        Text(package.name)
                            .font(.body)
                        Text(carrier.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(package.dimensions.formatted(unit: unit))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onToggleStar {
                VStack {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(.secondary)
                        .padding(Constants.horizontalPadding)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggleStar()
                }
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
    }

    @ViewBuilder
    private var carrierLogo: some View {
        if let logo = carrier.logo {
            Image(uiImage: logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.logoSize, height: Constants.logoSize)
        }
    }

}

private extension CarrierPackageRow {
    enum Constants {
        static let outerSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let logoSize: CGFloat = 36
    }
}
