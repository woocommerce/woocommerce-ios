/// Generates the names of the named colors in the ColorPalette.xcasset
enum MurielColorName: String, CustomStringConvertible {
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
        // can't use .capitalized because it lowercases the P and B in "wooCommercePurple"
        return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

/// Value of a Muriel color's shade
///
/// Note: There are a finite number of acceptable values. Not just any Int works.
///       Also, enum cases cannot begin with a number, thus the `shade` prefix.
enum MurielColorShade: Int, CustomStringConvertible {
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

/// A specific color and shade from the muriel palette's asset file
struct MurielColor {
    let name: MurielColorName
    let shade: MurielColorShade

    init(name: MurielColorName, shade: MurielColorShade = .shade50) {
        self.name = name
        self.shade = shade
    }

    init(from identifier: MurielColor, shade: MurielColorShade) {
        self.name = identifier.name
        self.shade = shade
    }

    // MARK: - Muriel's semantic colors
    static let pink = MurielColor(name: .pink)
    static let wooCommercePurple = MurielColor(name: .wooCommercePurple)
    static let red = MurielColor(name: .red)
    static let gray = MurielColor(name: .gray)
    static let blue = MurielColor(name: .blue)
    static let green = MurielColor(name: .green)
    static let warning = MurielColor(name: .yellow)
    static let text = MurielColor(name: .gray, shade: .shade80)

    /// The full name of the color, with required shade value
    func assetName() -> String {
        return "\(name)\(shade)"
    }
}
