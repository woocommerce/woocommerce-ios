import XCTest
@testable import Networking


/// JetpackRequest Unit Tests
///
final class JetpackRequestTests: XCTestCase {

    /// Testing API Version
    ///
    private let sampleWooApiVersion = WooAPIVersion.mark3

    /// Sample SiteID
    ///
    private let sampleSiteID: Int64 = 1234

    /// RPC Sample Method Path
    ///
    private let sampleRPC = "sample"

    /// Sample Parameters
    ///
    private let sampleParameters = ["some": "thing", "yo": "semite"]

    /// Base URL: Mapping the Sample Site + Jetpack Tunneling API
    ///
    private var jetpackEndpointBaseURL: String {
        return Settings.wordpressApiBaseURL + JetpackRequest.wordpressApiVersion.path + "jetpack-blogs/" + String(sampleSiteID) + "/rest-api/"
    }



    /// Verifies that a POST JetpackRequest will query the Jetpack Tunneled WordPress.com API.
    ///
    func test_post_request_queries_DotCom_Jetpack_tunnel_endpoint_with_no_extra_query_parameters() {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: sampleSiteID, path: sampleRPC, parameters: sampleParameters)

        let expectedURL = URL(string: jetpackEndpointBaseURL)!
        let generatedURL = try! request.asURLRequest().url!
        XCTAssertEqual(generatedURL, expectedURL)
    }

    /// Verifies that a POST JetpackRequest will serialize all of the Tunneling Parameters in the request body.
    ///
    func test_post_request_queries_DotCom_Jetpack_tunnel_endpoint_with_its_parameters_in_the_body() {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: sampleSiteID, path: sampleRPC, parameters: sampleParameters)

        guard let urlRequest = try? request.asURLRequest(),
            let generatedBodyAsData = urlRequest.httpBody,
            let generatedBody = String(data: generatedBodyAsData, encoding: .utf8)
        else {
            XCTFail()
            return
        }

        let expectedBody = httpBody(for: request)
        XCTAssertEqual(expectedBody, generatedBody)
    }

    /// Verifies that a GET JetpackRequest will query the Jetpack Tunneled WordPress.com API, with the expected query parameters.
    ///
    func test_get_request_queries_DotCom_Jetpack_tunnel_endpoint_with_expected_query_parameters() {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: sampleSiteID, path: sampleRPC)

        let expectedURL = URL(string: jetpackEndpointBaseURL + queryParameters(for: request))!
        let generatedURL = try! request.asURLRequest().url!
        XCTAssertEqual(generatedURL, expectedURL)
    }

    /// Verifies that a GET JetpackRequest will not serialize anything in the body.
    ///
    func test_get_request_does_not_serialize_anything_in_the_body() {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: sampleSiteID, path: sampleRPC, parameters: sampleParameters)

        let output = try! request.asURLRequest()
        XCTAssertNil(output.httpBody)
    }

    /// Verifies that a DELETE JetpackRequest will actually become a GET with a `&_method=delete` query string parameter.
    ///
    func test_delete_request_becomes_get_request() {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .delete, siteID: sampleSiteID, path: sampleRPC, parameters: sampleParameters)

        let output = try! request.asURLRequest()
        XCTAssertEqual(output.httpMethod?.uppercased(), "GET")
        XCTAssertTrue((output.url?.absoluteString.contains("%26_method%3Ddelete"))!)
    }

    /// Verifies that a PUT JetpackRequest will actually become a POST with a `_method=put` param in body
    ///
    func test_put_request_becomes_post_request() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark3, method: .put, siteID: sampleSiteID, path: sampleRPC, parameters: sampleParameters)

        // When
        let output = try request.asURLRequest()
        guard let urlRequest = try? request.asURLRequest(),
              let generatedBodyAsData = urlRequest.httpBody,
              let generatedBody = String(data: generatedBodyAsData, encoding: .utf8)
        else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(output.httpMethod?.uppercased(), "POST")
        XCTAssertTrue(generatedBody.contains("%26_method%3Dput"))
    }
}


// Parameter Encoding Helpers
//
private extension JetpackRequestTests {

    /// Returns the expected Query Parameters for a given JetpackRequest.
    ///
    func queryParameters(for request: JetpackRequest) -> String {
        switch request.method {
        case .get:
            let parameters = concatenate(request.parameters).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            let ampersandAsPercentEncoded = "&".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            let methodAsPercentEncoded = String("method=" + request.method.rawValue.lowercased())
                .addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            return "?json=true&path=" + sampleWooApiVersion.path + sampleRPC + parameters
                + ampersandAsPercentEncoded + "_" + methodAsPercentEncoded
        default:
            return String()
        }
    }

    /// Returns the expected HTTP Body for a given Jetpack Request.
    ///
    func httpBody(for request: JetpackRequest) -> String {
        guard request.method == .post else {
            return String()
        }

        let parametersAsData = try? JSONSerialization.data(withJSONObject: request.parameters, options: [])
        let parametersAsString = String(data: parametersAsData!, encoding: .utf8)!
        let parametersAsPercentEncoded = parametersAsString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let ampersandAsPercentEncoded = "&".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let methodAsPercentEncoded = String("method=" + request.method.rawValue.lowercased())
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics)!

        return "body=" + parametersAsPercentEncoded +
            "&json=true" +
            "&path=" + sampleWooApiVersion.path + sampleRPC +
            ampersandAsPercentEncoded + "_" + methodAsPercentEncoded
    }

    /// Concatenates the specified collection of Parameters for the URLRequest's httpBody.
    ///
    func concatenate(_ parameters: [String: Any]) -> String {
        return parameters.reduce("") { (output, parameter) in
            return output + "&" + parameter.key + "=" + String(describing: parameter.value)
        }
    }
}
