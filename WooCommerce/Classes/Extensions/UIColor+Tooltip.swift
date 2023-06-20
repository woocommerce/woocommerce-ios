import UIKit

extension UIColor {
    static var invertedSystem5: UIColor {
        UIColor(light: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                dark: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedLabel: UIColor {
        UIColor(light: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                dark: UIColor.label.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedSecondaryLabel: UIColor {
        UIColor(light: UIColor.secondaryLabel.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                dark: UIColor.secondaryLabel.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedLink: UIColor {
        UIColor(light: .wooCommercePurple(.shade30), dark: .wooCommercePurple(.shade50))
    }

    static var invertedSeparator: UIColor {
        UIColor(light: UIColor.separator.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                dark: UIColor.separator.color(for: UITraitCollection(userInterfaceStyle: .light)))
    }

    static var invertedTooltipBackgroundColor: UIColor {
        UIColor(light: UIColor.systemGray5.color(for: UITraitCollection(userInterfaceStyle: .dark)),
                dark: .white)
    }
}
