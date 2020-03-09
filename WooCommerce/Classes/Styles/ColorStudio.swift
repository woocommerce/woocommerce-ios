/// Generates the names of the named colors in the ColorPalette.xcasset
enum ColorStudioName: String, CustomStringConvertible {
    // MARK: - Base colors
    case blue
    case celadon
    case gray
    case green
    case orange
    case pink
    case purple
    case red
    case yellow
    case wooCommercePurple

    var description: String {
        // can't use .capitalized because it lowercases the C and P in "wooCommercePurple"
        return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

/// Value of a Muriel color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
enum ColorStudioShade: Int, CustomStringConvertible {
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

    var description: String {
        return "\(rawValue)"
    }
}


/// Conformance to CaseIterable will be useful for testing.
extension ColorStudioShade: CaseIterable { }


/// A specific color and shade from Color Studio
struct ColorStudio {
    let name: ColorStudioName
    let shade: ColorStudioShade

    init(name: ColorStudioName, shade: ColorStudioShade = .shade50) {
        self.name = name
        self.shade = shade
    }

    init(from identifier: ColorStudio, shade: ColorStudioShade) {
        self.name = identifier.name
        self.shade = shade
    }

    // MARK: - Muriel's semantic colors
    static let pink = ColorStudio(name: .pink)
    static let wooCommercePurple = ColorStudio(name: .wooCommercePurple)
    static let brand = ColorStudio(name: .wooCommercePurple, shade: .shade60)
    static let red = ColorStudio(name: .red)
    static let gray = ColorStudio(name: .gray)
    static let blue = ColorStudio(name: .blue)
    static let green = ColorStudio(name: .green)
    static let yellow = ColorStudio(name: .yellow)
    static let orange = ColorStudio(name: .orange)

    /// The full name of the color, with required shade value
    func assetName() -> String {
        return "\(name)\(shade)"
    }
}
