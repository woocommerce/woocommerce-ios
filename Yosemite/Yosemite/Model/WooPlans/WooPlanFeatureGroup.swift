import Foundation
import SwiftUI

public struct WooPlanFeatureGroup: Decodable {
    public let title: String
    public let description: String
    public let imageFilename: String
    public let imageCardColor: Color
    public let features: [WooPlanFeature]

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case imageFilename = "image_filename"
        case imageCardColor = "image_card_color"
        case features
    }

    public init(title: String,
                description: String,
                imageFilename: String,
                imageCardColor: Color,
                features: [WooPlanFeature]) {
        self.title = title
        self.description = description
        self.imageFilename = imageFilename
        self.imageCardColor = imageCardColor
        self.features = features
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        imageFilename = try container.decode(String.self, forKey: .imageFilename)

        let colorString = try container.decode(String.self, forKey: .imageCardColor)
        do {
            imageCardColor = try Color(rgbString: colorString)
        } catch is Color.ColorDecodingError {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.imageCardColor],
                                                    debugDescription: "Could not decode RGB color from found rgbString '\(colorString)'"))
        }

        features = try container.decode([WooPlanFeature].self, forKey: .features)
    }
}

public struct WooPlanFeature: Codable {
    public let title: String
    public let description: String
}

import RegexBuilder
extension Color {
    private typealias RGBComponents = (red: Double, green: Double, blue: Double, opacity: Double)

    init(rgbString: String) throws {
        let components: RGBComponents
        if #available(iOS 16.0, *) {
            components = try Color.colorComponents(from: rgbString)
        } else {
            components = try Color.legacyColorComponents(from: rgbString)
        }
        self = Color(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
    }

    @available(iOS 15.0, *)
    private static func legacyColorComponents(from rgbString: String) throws -> RGBComponents {
        let pattern = #"rgba\((\d+),\s*(\d+),\s*(\d+),\s*(\d+(\.\d+)?)\)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])

        guard let match = regex.firstMatch(in: rgbString, options: [], range: NSRange(location: 0, length: rgbString.count)) else {
            throw ColorDecodingError.invalidRGBStringProvided
        }

        let redRange = match.range(at: 1)
        let greenRange = match.range(at: 2)
        let blueRange = match.range(at: 3)
        let alphaRange = match.range(at: 4)

        let redString = (rgbString as NSString).substring(with: redRange)
        let greenString = (rgbString as NSString).substring(with: greenRange)
        let blueString = (rgbString as NSString).substring(with: blueRange)
        let alphaString = (rgbString as NSString).substring(with: alphaRange)

        guard let red = Double(redString),
              let green = Double(greenString),
              let blue = Double(blueString),
              let alpha = Double(alphaString) else {
            throw ColorDecodingError.invalidRGBStringProvided
        }

        return (red/255.0, green/255.0, blue/255.0, alpha)
    }

    @available(iOS 16.0, *)
    private static func colorComponents(from rgbString: String) throws -> RGBComponents {
        let componentMatcher: Regex<(Substring, Double, Double, Double, Double)> = Regex {
            "rgba("
            Capture {
                One(.localizedDouble(locale: .init(identifier: "en-us")))
            }
            ","
            ZeroOrMore(.whitespace)
            Capture {
                One(.localizedDouble(locale: .init(identifier: "en-us")))
            }
            ","
            ZeroOrMore(.whitespace)
            Capture {
                One(.localizedDouble(locale: .init(identifier: "en-us")))
            }
            ","
            ZeroOrMore(.whitespace)
            Capture {
                One(.localizedDouble(locale: .init(identifier: "en-us")))
            }
            ")"
          }
          .anchorsMatchLineEndings()
        guard let match = try componentMatcher.wholeMatch(in: rgbString) else {
            throw ColorDecodingError.invalidRGBStringProvided
        }
        let (_, red, green, blue, alpha) = match.output
        return (red/255, green/255, blue/255, alpha)
    }

    enum ColorDecodingError: Error {
        case invalidRGBStringProvided
    }
}
