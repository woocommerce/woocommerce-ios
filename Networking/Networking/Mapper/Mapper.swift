import Foundation


/// Defines a Mapping Entity that will be used to parse a Backend Response.
///
protocol Mapper {

    /// Defines the Mapping Return Type.
    ///
    associatedtype Output

    /// Maps a Backend Response into a generic entity of Type `Output`. This method *can throw* errors.
    ///
    func map(response: Data) throws -> Output
}


/// Default Remote Errors
///
enum MappingError: Error {

    /// Indicates that the Backend's Response is not in the expected format.
    ///
    case unknownFormat

    /// Indicates that the value for a mandatory key is missing.
    ///
    case missingKey
}
