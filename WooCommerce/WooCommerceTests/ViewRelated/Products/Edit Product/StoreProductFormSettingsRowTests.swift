import Testing
@testable import WooCommerce

struct StoreProductFormSettingsRowTests {
    @Test(arguments: [
        (0, "4.5", Double?.none),
        (2, "invalid", nil),
        (2, "nan", nil),
        (2, "inf", nil),
        (2, "4.5", 4.5)
    ])
    func test_review_when_rating_count_or_average_varies_then_only_available_averages_are_kept(count: Int, average: String, expected: Double?) throws {
        // Given
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .reviews, title: nil, details: nil)
        let row = ProductFormSection.SettingsRow.reviews(viewModel: viewModel, ratingCount: count, averageRating: average)

        // When
        let review = try #require(StoreProductFormSettingsRow(row).review)

        // Then
        #expect(review.average == expected)
    }
}
