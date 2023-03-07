/// Generates the names of the named colors in the ColorPalette.xcasset
public enum ColorStudioName: String, CustomStringConvertible {
    // MARK: - Base colors
    case blue
    case celadon
    case jetpackGreen
    case gray
    case green
    case orange
    case pink
    case purple
    case red
    case yellow
    case wooCommercePurple

    public var description: String {
        // can't use .capitalized because it lowercases the C and P in "wooCommercePurple"
        return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

/// Value of a Muriel color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
public enum ColorStudioShade: Int, CustomStringConvertible {
    case shade0 = 0
    case shade5 = 5
    case shade10 = 10
    case shade20 = 20
    case shade30 = 30
    case shade40 = 40
    case shade50 = 50
    case shade60 = 60
    case shade70 = 70
    case shade80 = 80
    case shade90 = 90
    case shade100 = 100

    public var description: String {
        return "\(rawValue)"
    }
}


/// Conformance to CaseIterable will be useful for testing.
extension ColorStudioShade: CaseIterable { }


/// A specific color and shade from Color Studio
public struct ColorStudio {
    let name: ColorStudioName
    let shade: ColorStudioShade

    public init(name: ColorStudioName, shade: ColorStudioShade = .shade50) {
        self.name = name
        self.shade = shade
    }

    public init(from identifier: ColorStudio, shade: ColorStudioShade) {
        self.name = identifier.name
        self.shade = shade
    }

    // MARK: - Muriel's semantic colors
    public static let pink = ColorStudio(name: .pink)
    public static let wooCommercePurple = ColorStudio(name: .wooCommercePurple)
    public static let brand = ColorStudio(name: .wooCommercePurple, shade: .shade60)
    public static let red = ColorStudio(name: .red)
    public static let gray = ColorStudio(name: .gray)
    public static let blue = ColorStudio(name: .blue)
    public static let jetpackGreen = ColorStudio(name: .jetpackGreen)
    public static let green = ColorStudio(name: .green)
    public static let yellow = ColorStudio(name: .yellow)
    public static let orange = ColorStudio(name: .orange)
    public static let celadon = ColorStudio(name: .celadon)

    /// The full name of the color, with required shade value
    public func assetName() -> String {
        return "\(name)\(shade)"
    }
}
