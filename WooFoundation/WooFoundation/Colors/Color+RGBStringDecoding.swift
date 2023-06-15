import Foundation
import SwiftUI
import RegexBuilder

extension Color {
    private typealias RGBComponents = (red: Double, green: Double, blue: Double, opacity: Double)

    public init(rgbString: String) throws {
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
        let componentMatcher: Regex<(Substring, Int, Int, Int, Double)> = Regex {
            "rgba("
            Capture {
                One(.localizedInteger(locale: .init(identifier: "en-us")))
            }
            ","
            ZeroOrMore(.whitespace)
            Capture {
                One(.localizedInteger(locale: .init(identifier: "en-us")))
            }
            ","
            ZeroOrMore(.whitespace)
            Capture {
                One(.localizedInteger(locale: .init(identifier: "en-us")))
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
        return (Double(red)/255, Double(green)/255, Double(blue)/255, alpha)
    }

    public enum ColorDecodingError: Error {
        case invalidRGBStringProvided
    }
}
