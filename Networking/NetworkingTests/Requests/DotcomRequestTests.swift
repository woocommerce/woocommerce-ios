import Foundation
import XCTest
@testable import Networking


/// WordPress.com Requests Unit Tests
///
class DotcomRequestTests: XCTestCase {

    /// RPC Sample Method Path
    ///
    private let sampleRPC = "sample"

    /// Sample Parameters
    ///
    private let sampleParameters = ["some": "thing", "yo": "semite"]

    /// Sample Parameters as a Query String
    ///
    private var sampleParametersForQuery: String {
        return "?" + sampleParametersForBody
    }

    /// Sample Parameters as a Body String
    ///
    private var sampleParametersForBody: String {
        return encodeAsBodyString(parameters: sampleParameters)
    }



    /// Verifies that the DotcomRequest's generated URL contains the `BaseURL + API Version + RPC Name`.
    ///
    func testRequestUrlContainsExpectedComponents() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: sampleRPC)

        let expectedURL = URL(string: Settings.wordpressApiBaseURL + request.wordpressApiVersion.path + sampleRPC)!
        let generatedURL = try! request.asURLRequest().url!
        XCTAssertEqual(expectedURL, generatedURL)
    }

    /// Verifies that the DotcomRequest's generated URL contains the Parameters serialized as part of the query, when the method is `get`.
    ///
    func testParametersAreSerializedAsPartOfTheUrlQueryWhenMethodIsSetToGet() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: sampleRPC, parameters: sampleParameters)

        let expectedURL = URL(string: Settings.wordpressApiBaseURL + request.wordpressApiVersion.path + sampleRPC + sampleParametersForQuery)!
        let generatedURL = try! request.asURLRequest().url!

        /// Note: Why not compare URL's directly?. As of iOS 12, URLQueryItem's serialization to string can result in swizzled entries.
        /// (Exact same result, but shuffled order!). For that reason we compare piece by piece!.
        ///
        let expectedComponents = URLComponents(url: expectedURL, resolvingAgainstBaseURL: false)!
        let generatedComponents = URLComponents(url: generatedURL, resolvingAgainstBaseURL: false)!

        let expectedQueryItems = Set(generatedComponents.queryItems!)
        let generatedQueryItems = Set(expectedComponents.queryItems!)

        XCTAssertEqual(expectedComponents.scheme, generatedComponents.scheme)
        XCTAssertEqual(expectedComponents.percentEncodedHost, generatedComponents.percentEncodedHost)
        XCTAssertEqual(expectedComponents.percentEncodedPath, generatedComponents.percentEncodedPath)
        XCTAssertEqual(expectedQueryItems, generatedQueryItems)
    }

    /// Verifies that the DotcomRequest's generated URL does NOT contain the Parameters serialized as part of the query, when the method is `post`.
    ///
    func testParametersAreNotSerializedAsPartOfTheUrlQueryWhenMethodIsSetToPost() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: sampleRPC, parameters: sampleParameters)

        let generatedURL = try! request.asURLRequest().url!
        let expectedURL = URL(string: Settings.wordpressApiBaseURL + request.wordpressApiVersion.path + sampleRPC)!
        XCTAssertEqual(expectedURL, generatedURL)
    }

    /// Verifies that the DotcomRequest's generated httpBody contains the Parameters, serialized as expected.
    ///
    func testParametersAreSerializedAsPartOfTheBodyWhenMethodIsSetToPost() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: sampleRPC, parameters: sampleParameters)

        let generatedBodyAsData = try! request.asURLRequest().httpBody!
        let generatedBodyAsString = String(data: generatedBodyAsData, encoding: .utf8)
        let generatedBodyParameters = generatedBodyAsString!.split(separator: Character("&"))

        /// Note: As of iOS 12 the parameters were being serialized at random positions. That's *why* this test is a bit extra complex!
        ///
        for parameter in generatedBodyParameters {
            let components = parameter.split(separator: Character("="))
            let key = String(components[0])
            let value = String(components[1])

            XCTAssertEqual(value, sampleParameters[key])
        }
    }
}


/// Parameter Encoding Helpers
///
private extension DotcomRequestTests {

    /// Encodes the specified collection of Parameters for the URLRequest's httpBody
    ///
    func encodeAsBodyString(parameters: [String: String]) -> String {
        return parameters.reduce("") { (output, parameter) in
            let prefix = output.isEmpty ? "" : "&"
            return output + prefix + parameter.key + "=" + parameter.value
        }
    }
}
