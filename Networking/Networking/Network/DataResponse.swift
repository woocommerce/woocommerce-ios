
import Foundation

public struct DataResponse {
    public let result: Result<Data, Error>
    public let totalDuration: TimeInterval
}
