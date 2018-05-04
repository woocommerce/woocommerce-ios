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

        let expectedURL = URL(string: request.wordpressApiBaseURL + request.wordpressApiVersion.path + sampleRPC)
        let generatedURL = try? request.asURLRequest().url
        XCTAssertEqual(expectedURL, generatedURL)
    }

    /// Verifies that the DotcomRequest's generated URL contains the Parameters serialized as part of the query, when the method is `get`.
    ///
    func testParametersAreSerializedAsPartOfTheUrlQueryWhenMethodIsSetToGet() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: sampleRPC, parameters: sampleParameters)

        let expectedURL = URL(string: request.wordpressApiBaseURL + request.wordpressApiVersion.path + sampleRPC + sampleParametersForQuery)
        let generatedURL = try? request.asURLRequest().url
        XCTAssertEqual(expectedURL, generatedURL)
    }

    /// Verifies that the DotcomRequest's generated URL does NOT contain the Parameters serialized as part of the query, when the method is `post`.
    ///
    func testParametersAreNotSerializedAsPartOfTheUrlQueryWhenMethodIsSetToPost() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: sampleRPC, parameters: sampleParameters)
        let generatedURL = try? request.asURLRequest().url

        let expectedURL = URL(string: request.wordpressApiBaseURL + request.wordpressApiVersion.path + sampleRPC)!
        XCTAssertEqual(expectedURL, generatedURL)
    }

    /// Verifies that the DotcomRequest's generated httpBody contains the Parameters, serialized sa expected.
    ///
    func testParametersAreSerializedAsPartOfTheBodyWhenMethodIsSetToPost() {
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: sampleRPC, parameters: sampleParameters)

        let generatedBodyAsData = try! request.asURLRequest().httpBody
        let generatedBodyAsString = String(data: generatedBodyAsData!, encoding: .utf8)
        XCTAssertEqual(generatedBodyAsString, sampleParametersForBody)
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
