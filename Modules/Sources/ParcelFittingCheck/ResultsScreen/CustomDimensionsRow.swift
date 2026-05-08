import SwiftUI

struct CustomDimensionsRow: View {
    let dimensions: ParcelDimensions
    let unit: UnitLength
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Constants.spacing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
                    .font(.title2)

                VStack(alignment: .leading, spacing: Constants.textSpacing) {
                    Text(Localization.customDimensions)
                        .font(.body)
                    Text(dimensions.formatted(unit: unit))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
    }

}

private extension CustomDimensionsRow {
    enum Constants {
        static let spacing: CGFloat = 12
        static let textSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
    }

    enum Localization {
        static let customDimensions = "Custom dimensions"
    }
}
