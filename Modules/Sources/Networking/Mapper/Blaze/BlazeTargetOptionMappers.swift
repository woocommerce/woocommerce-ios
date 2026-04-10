import Foundation

/// Mapper: `BlazeTargetLanguage`
///
struct BlazeTargetLanguageListMapper: Mapper {

    /// Locale of the response.
    let locale: String

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetLanguage]`.
    ///
    func map(response: Data) throws -> [BlazeTargetLanguage] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .locale: locale
        ]
        return try decoder.decode(BlazeTargetLanguageList.self, from: response).languages
    }

    struct BlazeTargetLanguageList: Decodable {
        let languages: [BlazeTargetLanguage]
    }
}

/// Mapper: `BlazeTargetDevice`
///
struct BlazeTargetDeviceListMapper: Mapper {

    /// Locale of the response.
    let locale: String

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetDevice]`.
    ///
    func map(response: Data) throws -> [BlazeTargetDevice] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .locale: locale
        ]
        return try decoder.decode(BlazeTargetDeviceList.self, from: response).devices
    }

    struct BlazeTargetDeviceList: Decodable {
        let devices: [BlazeTargetDevice]
    }
}

/// Mapper: `BlazeTargetTopic`
///
struct BlazeTargetTopicListMapper: Mapper {

    /// Locale of the response.
    let locale: String

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetTopic]`.
    ///
    func map(response: Data) throws -> [BlazeTargetTopic] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.userInfo = [
            .locale: locale
        ]
        return try decoder.decode(BlazeTargetTopicList.self, from: response).pageTopics
    }

    struct BlazeTargetTopicList: Decodable {
        let pageTopics: [BlazeTargetTopic]
    }
}

/// Mapper: `BlazeTargetLocation`
///
struct BlazeTargetLocationListMapper: Mapper {

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetLocation]`.
    ///
    func map(response: Data) throws -> [BlazeTargetLocation] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(BlazeTargetLocationList.self, from: response).locations
    }

    struct BlazeTargetLocationList: Decodable {
        let locations: [BlazeTargetLocation]
    }
}
