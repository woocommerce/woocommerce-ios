import Foundation

/// Sources:
/// - https://github.com/Automattic/Gravatar-SDK-iOS/blob/trunk/Sources/Gravatar/Options/Rating.swift
/// - https://github.com/Automattic/Gravatar-SDK-iOS/blob/trunk/Sources/Gravatar/OpenApi/Generated/AvatarRating.swift
/// Gravatar allows users to self-rate their images so that they can indicate if an image is appropriate for a certain audience. By default, only `general`
/// rated
/// images are displayed unless you indicate that you would like to see higher ratings.
///
/// If the requested email hash does not have an image meeting the requested rating level, then the default avatar is returned (See: ``DefaultAvatarOption``)
public enum Rating: String, Sendable, CaseIterable {
    /// Suitable for display on all websites with any audience type.
    case general = "g"
    /// May contain rude gestures, provocatively dressed individuals, the lesser swear words, or mild violence.
    case parentalGuidance = "pg"
    /// May contain such things as harsh profanity, intense violence, nudity, or hard drug use.
    case restricted = "r"
    /// May contain sexual imagery or extremely disturbing violence.
    case x
}

extension Rating {
    func toAvatarRating() -> AvatarRating {
        switch self {
        case .general:
            .g
        case .parentalGuidance:
            .pg
        case .restricted:
            .r
        case .x:
            .x
        }
    }
}

/// Rating associated with the image.
///
enum AvatarRating: String, Codable, CaseIterable {
    case g = "G"
    case pg = "PG"
    case r = "R"
    case x = "X"
}
