import Foundation

public struct WooPlanFeatureGroup: Codable {
    public let title: String
    public let description: String
    public let imageFilename: String
    public let imageCardColor: UIColor
    public let features: [WooPlanFeature]

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case imageFilename = "image_filename"
        case imageCardColor = "image_card_color"
        case features
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        imageFilename = try container.decode(String.self, forKey: .imageFilename)

        let colorString = try container.decode(String.self, forKey: .imageCardColor)
        imageCardColor = try UIColor(rgbString: colorString)

        features = try container.decode([WooPlanFeature].self, forKey: .features)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(imageFilename, forKey: .imageFilename)

        let colorString = imageCardColor.rgbStringRepresentation
        try container.encode(colorString, forKey: .imageCardColor)

        try container.encode(features, forKey: .features)
    }
}

public struct WooPlanFeature: Codable {
    public let title: String
    public let description: String
}

extension UIColor {
    convenience init(rgbString: String) throws {
        let pattern = #"rgba\((\d+),\s*(\d+),\s*(\d+),\s*(\d+(\.\d+)?)\)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])

        guard let match = regex.firstMatch(in: rgbString, options: [], range: NSRange(location: 0, length: rgbString.count)) else {
            throw UIColorDecodingError.invalidRGBStringProvided
        }

        let redRange = match.range(at: 1)
        let greenRange = match.range(at: 2)
        let blueRange = match.range(at: 3)
        let alphaRange = match.range(at: 4)

        let redString = (rgbString as NSString).substring(with: redRange)
        let greenString = (rgbString as NSString).substring(with: greenRange)
        let blueString = (rgbString as NSString).substring(with: blueRange)
        let alphaString = (rgbString as NSString).substring(with: alphaRange)

        guard let red = Float(redString),
              let green = Float(greenString),
              let blue = Float(blueString),
              let alpha = Float(alphaString) else {
            throw UIColorDecodingError.invalidRGBStringProvided
        }

        self.init(red: CGFloat(red / 255.0),
                  green: CGFloat(green / 255.0),
                  blue: CGFloat(blue / 255.0),
                  alpha: CGFloat(alpha))
    }

    var rgbStringRepresentation: String {
        let components = self.cgColor.components
        let red = Float(components?[0] ?? 0.0) * 255.0
        let green = Float(components?[1] ?? 0.0) * 255.0
        let blue = Float(components?[2] ?? 0.0) * 255.0
        let alpha = Float(components?[3] ?? 0.0)

        return String(format: "rgba(%.0f, %.0f, %.0f, %.1f)", red, green, blue, alpha)
    }

    enum UIColorDecodingError: Error {
        case invalidRGBStringProvided
    }
}
