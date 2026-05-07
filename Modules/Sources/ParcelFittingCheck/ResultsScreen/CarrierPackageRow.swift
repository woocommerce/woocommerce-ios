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
                        Text(formattedDimensions)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onToggleStar {
                Button(action: onToggleStar) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
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

    private var formattedDimensions: String {
        String(format: Constants.dimensionsFormat,
               package.length, package.width, package.height,
               unit.symbol)
    }
}

private extension CarrierPackageRow {
    enum Constants {
        static let outerSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let logoSize: CGFloat = 36
        static let dimensionsFormat = "%.2f × %.2f × %.2f %@"
    }

    enum Localization {
    }
}
