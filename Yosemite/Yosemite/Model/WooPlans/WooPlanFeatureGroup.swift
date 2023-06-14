import Foundation
import SwiftUI
import WooFoundation

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
