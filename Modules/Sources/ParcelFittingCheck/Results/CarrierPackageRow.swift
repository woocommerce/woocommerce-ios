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
        PackageSelectionRow(isSelected: isSelected, onSelect: onSelect) {
            HStack(spacing: Constants.contentSpacing) {
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
            }
        } trailing: {
            if let onToggleStar {
                VStack {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(.secondary)
                        .padding(Constants.starPadding)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggleStar()
                }
            }
        }
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
        static let contentSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 2
        static let logoSize: CGFloat = 36
        static let starPadding: CGFloat = 16
    }
}
