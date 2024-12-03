import Foundation
import SwiftUI
import RegexBuilder

extension Color {
    private typealias RGBComponents = (red: Double, green: Double, blue: Double, opacity: Double)

    public init(rgbString: String) throws {
        let components = try Color.colorComponents(from: rgbString)
        self = Color(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
    }

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
