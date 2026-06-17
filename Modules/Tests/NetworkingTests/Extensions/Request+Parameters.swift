import Foundation
@testable import NetworkingCore

extension DotcomRequest {
    var parameters: [String: Any]? {
        requestParameters.testAnyDictionary
    }
}

extension JetpackRequest {
    var parameters: [String: Any] {
        requestParameters.testAnyDictionary ?? [:]
    }
}

extension RESTRequest {
    var parameters: [String: Any]? {
        requestParameters.testAnyDictionary
    }
}

extension Request {
    var jsonBodyParameters: [String: Any]? {
        guard let body = try? asURLRequest().httpBody else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: body) as? [String: Any]
    }
}

private extension RequestParameters {
    var testAnyDictionary: [String: Any]? {
        dictionary.map(Self.anyDictionary)
    }

    static func anyDictionary(from parameters: RequestParameterDictionary) -> [String: Any] {
        parameters.reduce(into: [String: Any]()) { output, element in
            output[element.key] = anyValue(from: element.value)
        }
    }

    static func anyValue(from value: RequestParameterValue) -> Any {
        switch value {
        case .string(let value):
            return value
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .int64(let value):
            return value
        case .uint(let value):
            return value
        case .uint64(let value):
            return value
        case .double(let value):
            return value
        case .decimal(let value):
            return value
        case .null:
            return NSNull()
        case .array(let values):
            return values.map(anyValue)
        case .dictionary(let values):
            return anyDictionary(from: values)
        }
    }
}
