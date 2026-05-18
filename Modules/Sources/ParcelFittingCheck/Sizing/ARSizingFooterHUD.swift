import SwiftUI

struct ARSizingFooterHUD: View {
    let dimensions: ParcelDimensions
    let unit: UnitLength
    let hintsVisible: Bool
    let onShowHints: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ARGlassCard {
            VStack(spacing: 12) {
                measuredRow
                dimensionTiles
                confirmButton
            }
        }
    }

    private var measuredRow: some View {
        HStack {
            Text(Localization.measured)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.55))

            Spacer()

            if !hintsVisible {
                Button(action: onShowHints) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .accessibilityLabel(Localization.showHints)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: hintsVisible)
    }

    private var dimensionTiles: some View {
        HStack(spacing: 8) {
            DimensionTile(label: ParcelDimensions.Localization.lengthLabel,
                          value: ParcelDimensions.formatValue(dimensions.length),
                          unit: unit.symbol)
            DimensionTile(label: ParcelDimensions.Localization.widthLabel,
                          value: ParcelDimensions.formatValue(dimensions.width),
                          unit: unit.symbol)
            DimensionTile(label: ParcelDimensions.Localization.heightLabel,
                          value: ParcelDimensions.formatValue(dimensions.height),
                          unit: unit.symbol)
        }
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text(Localization.useTheseDimensions)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}

private struct DimensionTile: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.55))

            Text(value)
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension ARSizingFooterHUD {
    enum Localization {
        static let measured = NSLocalizedString(
            "parcelFitting.sizing.measured",
            value: "MEASURED",
            comment: "Label above the dimension tiles in the AR sizing footer")
        static let useTheseDimensions = NSLocalizedString(
            "parcelFitting.sizing.useTheseDimensions",
            value: "Use these dimensions",
            comment: "Button to confirm the measured dimensions in the AR sizing view")
        static let showHints = NSLocalizedString(
            "parcelFitting.sizing.showHints.accessibilityLabel",
            value: "Show tips",
            comment: "Accessibility label for the info button that reopens the AR coaching hints")
    }
}
