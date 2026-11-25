import CoreGraphics

public struct StoreCellConfiguration: Sendable {
    public enum Density: Sendable {
        case standard
        case compact

        var verticalPadding: CGFloat {
            self == .compact ? StorePadding.p4 : StorePadding.p7
        }

        var trailingSpacing: CGFloat {
            self == .compact ? StoreSpacing.s5 : StoreSpacing.s6
        }

        var minimumHeight: CGFloat? {
            self == .compact ? StoreSize.compactCellHeight : nil
        }
    }

    /// Color role for the leading icon and disclosure indicator.
    public enum IconTint: Sendable {
        case secondary
        case title
    }

    let density: Density
    let iconTint: IconTint

    public init(density: Density = .standard, iconTint: IconTint = .secondary) {
        self.density = density
        self.iconTint = iconTint
    }
}
