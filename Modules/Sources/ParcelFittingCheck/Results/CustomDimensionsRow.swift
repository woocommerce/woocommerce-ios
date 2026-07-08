import SwiftUI

struct CustomDimensionsRow: View {
    let dimensions: ParcelDimensions
    let unit: UnitLength
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        PackageSelectionRow(isSelected: isSelected, onSelect: onSelect) {
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(Localization.customDimensions)
                    .font(.body)
                Text(dimensions.formatted(unit: unit))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension CustomDimensionsRow {
    enum Constants {
        static let textSpacing: CGFloat = 2
    }

    enum Localization {
        static let customDimensions = NSLocalizedString(
            "parcelFitting.results.customDimensions",
            value: "Custom dimensions",
            comment: "Label for the custom dimensions option on the AR results screen")
    }
}
