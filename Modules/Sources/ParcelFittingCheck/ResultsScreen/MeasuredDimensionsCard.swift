import SwiftUI

struct MeasuredDimensionsCard: View {
    let dimensions: ParcelDimensions
    let unit: UnitLength

    var body: some View {
        Text(formattedDimensions)
            .font(.title2.bold().monospacedDigit())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }

    private var formattedDimensions: String {
        String(format: Constants.dimensionsFormat,
               dimensions.length, dimensions.width, dimensions.height,
               unit.symbol)
    }
}

private extension MeasuredDimensionsCard {
    enum Constants {
        static let cornerRadius: CGFloat = 12
        static let dimensionsFormat = "%.2f × %.2f × %.2f %@"
    }
}
