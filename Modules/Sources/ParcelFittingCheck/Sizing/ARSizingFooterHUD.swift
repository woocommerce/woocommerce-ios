import SwiftUI

struct ARSizingFooterHUD: View {
    let dimensions: ParcelDimensions
    let unit: UnitLength
    let hintsVisible: Bool
    let onShowHints: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ARGlassCard {
            VStack(spacing: Constants.contentSpacing) {
                measuredRow
                dimensionTiles
                confirmButton
            }
        }
    }

    private var measuredRow: some View {
        HStack {
            Text(Localization.measured)
                .font(.caption2.weight(.semibold))
                .tracking(Constants.measuredTracking)
                .foregroundStyle(.white.opacity(Constants.secondaryOpacity))

            Spacer()

            Button(action: onShowHints) {
                Image(systemName: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .frame(width: Constants.infoButtonSize, height: Constants.infoButtonSize)
                    .background(Color.white.opacity(Constants.infoButtonBackgroundOpacity), in: Circle())
            }
            .accessibilityLabel(Localization.showHints)
            .opacity(hintsVisible ? 0 : 1)
            .allowsHitTesting(!hintsVisible)
        }
        .animation(.easeOut(duration: Constants.infoButtonAnimationDuration), value: hintsVisible)
    }

    private var dimensionTiles: some View {
        HStack(spacing: Constants.tileSpacing) {
            ARDimensionTile(label: ParcelDimensions.Localization.lengthLabel,
                            value: ParcelDimensions.formatValue(dimensions.length),
                            unit: unit.symbol)
            ARDimensionTile(label: ParcelDimensions.Localization.widthLabel,
                            value: ParcelDimensions.formatValue(dimensions.width),
                            unit: unit.symbol)
            ARDimensionTile(label: ParcelDimensions.Localization.heightLabel,
                            value: ParcelDimensions.formatValue(dimensions.height),
                            unit: unit.symbol)
        }
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text(Localization.useTheseDimensions)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.confirmButtonVerticalPadding)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}

private extension ARSizingFooterHUD {
    enum Constants {
        static let contentSpacing: CGFloat = 12
        static let measuredTracking: CGFloat = 1.2
        static let secondaryOpacity: Double = 0.55
        static let infoButtonSize: CGFloat = 22
        static let infoButtonBackgroundOpacity: Double = 0.10
        static let infoButtonAnimationDuration: Double = 0.18
        static let tileSpacing: CGFloat = 8
        static let confirmButtonVerticalPadding: CGFloat = 12
    }

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
