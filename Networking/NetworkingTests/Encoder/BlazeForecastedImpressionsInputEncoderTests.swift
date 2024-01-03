import XCTest
@testable import Networking

final class BlazeForecastedImpressionsInputEncoderTests: XCTestCase {

    func test_blazeForecastedImpressionsInput_encoder_encodes_necessary_fields_correctly() throws {
        // Given
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.date(from: "2023-12-05")!
        let endDate = dateFormatter.date(from: "2023-12-11")!
        let formattedTotalBudget = "35.00"
        let targetOptions = BlazeTargetOptions(locations: [29211, 42546],
                                               languages: ["en", "de"],
                                               devices: ["mobile"],
                                               pageTopics: ["IAB3", "IAB4"])
        let input = BlazeForecastedImpressionsInput(startDate: startDate,
                                                    endDate: endDate,
                                                    formattedTotalBudget: formattedTotalBudget,
                                                    targetings: targetOptions)

        // When
        let parameters = try input.toDictionary(keyEncodingStrategy: .convertToSnakeCase, dateFormatter: dateFormatter)

        // Then
        XCTAssertEqual(parameters["start_date"] as? String, "2023-12-05")
        XCTAssertEqual(parameters["end_date"] as? String, "2023-12-11")
        XCTAssertEqual(parameters["total_budget"] as? String, "35.00")

        let targetingsParams = parameters["targetings"] as! [String: Any]
        XCTAssertEqual(targetingsParams["locations"] as? [Int64], [29211, 42546])
        XCTAssertEqual(targetingsParams["languages"] as? [String], ["en", "de"])
        XCTAssertEqual(targetingsParams["devices"] as? [String], ["mobile"])
        XCTAssertEqual(targetingsParams["page_topics"] as? [String], ["IAB3", "IAB4"])
    }
}
