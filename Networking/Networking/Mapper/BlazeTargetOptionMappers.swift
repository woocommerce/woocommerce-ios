import Foundation

/// Mapper: `BlazeTargetLanguage`
///
struct BlazeTargetLanguageListMapper: Mapper {

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetLanguage]`.
    ///
    func map(response: Data) throws -> [BlazeTargetLanguage] {
        let decoder = JSONDecoder()
        return try decoder.decode([BlazeTargetLanguage].self, from: response)
    }
}

/// Mapper: `BlazeTargetDevice`
///
struct BlazeTargetDeviceListMapper: Mapper {

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetDevice]`.
    ///
    func map(response: Data) throws -> [BlazeTargetDevice] {
        let decoder = JSONDecoder()
        return try decoder.decode([BlazeTargetDevice].self, from: response)
    }
}

/// Mapper: `BlazeTargetTopic`
///
struct BlazeTargetTopicListMapper: Mapper {

    /// (Attempts) to convert a list of dictionary into `[BlazeTargetTopic]`.
    ///
    func map(response: Data) throws -> [BlazeTargetTopic] {
        let decoder = JSONDecoder()
        return try decoder.decode([BlazeTargetTopic].self, from: response)
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
        return try decoder.decode([BlazeTargetLocation].self, from: response)
    }
}