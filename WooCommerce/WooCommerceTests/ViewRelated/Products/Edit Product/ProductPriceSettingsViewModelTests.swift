import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductPriceSettingsViewModelTests: XCTestCase {

    // MARK: - Initialization

    func testHandlingNilRetrievedTaxClass() {
        // Arrange
        let mockStoresManager = MockTaxClassStoresManager(missingTaxClass: nil, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let originalTaxClass = "zero"
        let product = MockProduct().product(taxClass: originalTaxClass)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxClass?.slug, originalTaxClass)

        // Act
        let expectation = self.expectation(description: "Wait for retrieving product tax class")
        viewModel.retrieveProductTaxClass {
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Assert
        XCTAssertEqual(viewModel.taxClass?.slug, "standard")
    }

    func testHandlingNonNilRetrievedTaxClass() {
        // Arrange
        let taxClass = TaxClass(siteID: 18, name: "Lowest tax", slug: "nice-tax-class")
        let mockStoresManager = MockTaxClassStoresManager(missingTaxClass: taxClass, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let originalTaxClass = ""
        let product = MockProduct().product(taxClass: originalTaxClass)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        // An empty tax class slug defaults to the standard tax class.
        XCTAssertEqual(viewModel.taxClass?.slug, "standard")

        // Act
        let expectation = self.expectation(description: "Wait for retrieving product tax class")
        viewModel.retrieveProductTaxClass {
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Assert
        XCTAssertEqual(viewModel.taxClass?.slug, taxClass.slug)
    }

    // MARK: - UI changes

    // Regular price

    func testHandlingNilRegularPrice() {
        let regularPrice = "3.6"
        let product = MockProduct().product(regularPrice: regularPrice)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.regularPrice, regularPrice)

        viewModel.handleRegularPriceChange(nil)
        XCTAssertEqual(viewModel.regularPrice, nil)
    }

    func testHandlingNonNilRegularPrice() {
        let product = MockProduct().product(regularPrice: nil)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.regularPrice, nil)

        let regularPrice = "3.6"
        viewModel.handleRegularPriceChange(regularPrice)
        XCTAssertEqual(viewModel.regularPrice, regularPrice)
    }

    // Sale price

    func testHandlingNilSalePrice() {
        let salePrice = "3.6"
        let product = MockProduct().product(salePrice: salePrice)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.salePrice, salePrice)

        viewModel.handleSalePriceChange(nil)
        XCTAssertEqual(viewModel.salePrice, nil)
    }

    func testHandlingNonNilSalePrice() {
        let product = MockProduct().product(salePrice: nil)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.salePrice, nil)

        let salePrice = "3.6"
        viewModel.handleSalePriceChange(salePrice)
        XCTAssertEqual(viewModel.salePrice, salePrice)
    }

    // Tax class

    func testHandlingNilTaxClass() {
        let originalTaxClass = "zero"
        let product = MockProduct().product(taxClass: originalTaxClass)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxClass?.slug, originalTaxClass)

        viewModel.handleTaxClassChange(nil)
        XCTAssertEqual(viewModel.taxClass, nil)
    }

    func testHandlingNonNilTaxClass() {
        let originalTaxClass = "zero"
        let product = MockProduct().product(taxClass: originalTaxClass)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxClass?.slug, originalTaxClass)

        let taxClass = TaxClass(siteID: 18, name: "Lowest tax", slug: "nice-tax-class")
        viewModel.handleTaxClassChange(taxClass)
        XCTAssertEqual(viewModel.taxClass?.slug, taxClass.slug)
    }

    // Tax status

    func testHandlingTaxStatus() {
        let originalTaxStatus = ProductTaxStatus.shipping
        let product = MockProduct().product(taxStatus: originalTaxStatus)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxStatus, originalTaxStatus)

        let taxStatus = ProductTaxStatus.taxable
        viewModel.handleTaxStatusChange(taxStatus)
        XCTAssertEqual(viewModel.taxStatus, taxStatus)
    }

    // Schedule sale toggle

    func testHandlingDisabledScheduleSale() {
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-28T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        viewModel.handleScheduleSaleChange(isEnabled: false)
        XCTAssertEqual(viewModel.dateOnSaleStart, nil)
        XCTAssertEqual(viewModel.dateOnSaleEnd, nil)
    }

    func testHandlingEnabledScheduleSaleFromNilSaleDates() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let product = MockProduct().product(dateOnSaleStart: nil, dateOnSaleEnd: nil)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, nil)
        XCTAssertEqual(viewModel.dateOnSaleEnd, nil)

        let expectedSaleStartDate = Date().startOfDay(timezone: timezone)
        let expectedSaleEndDate = Calendar.current.date(byAdding: .day, value: 1, to: Date().endOfDay(timezone: timezone))
        viewModel.handleScheduleSaleChange(isEnabled: true)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedSaleEndDate)
    }

    func testHandlingEnabledScheduleSaleFromExistingSaleDates() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-28T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        viewModel.handleScheduleSaleChange(isEnabled: true)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)
    }

    // Sale start date

    func testHandlingSaleStartDateWithoutSaleEndDate() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate: Date? = nil
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        let saleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-20T21:30:00")!
        viewModel.handleSaleStartDateChange(saleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleStart, saleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)
    }

    func testHandlingSaleStartDateWithAnEarlierSaleEndDate() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-18T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        let saleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-20T21:30:00")!
        let expectedStartDate = saleStartDate.startOfDay(timezone: timezone)
        let expectedEndDate = saleStartDate.endOfDay(timezone: timezone)
        viewModel.handleSaleStartDateChange(saleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleStartDateWithALaterSaleEndDate() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-18T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        let saleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-16T21:30:00")!
        let expectedStartDate = saleStartDate.startOfDay(timezone: timezone)
        let expectedEndDate = originalSaleEndDate
        viewModel.handleSaleStartDateChange(saleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // Sale end date

    func testHandlingSaleEndDateWithoutSaleStartDate() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate: Date? = nil
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        let saleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-20T21:30:00")!
        let expectedStartDate: Date? = nil
        let expectedEndDate = saleEndDate
        viewModel.handleSaleEndDateChange(saleEndDate)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleEndDateWithAnEarlierSaleStartDate() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-27T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        let saleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-20T21:30:00")!
        let expectedStartDate = originalSaleStartDate
        let expectedEndDate = saleEndDate.endOfDay(timezone: timezone)
        viewModel.handleSaleEndDateChange(saleEndDate)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleEndDateWithALaterSaleStartDate() {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-27T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        let saleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-01T21:30:00")!
        let expectedStartDate = originalSaleStartDate
        let expectedEndDate = originalSaleEndDate
        viewModel.handleSaleEndDateChange(saleEndDate)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // MARK: - Navigation actions

    // `completeUpdating`

    func testCompletingUpdatingWithSalePriceOnly() {
        let product = MockProduct().product()
        let viewModel = ProductPriceSettingsViewModel(product: product)

        let regularPrice = ""
        let salePrice = "17"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (_, _, _, _, _, _) in
            XCTFail("Completion block should not be called")
        }, onError: { error in
            XCTAssertEqual(error, .salePriceWithoutRegularPrice)
            expectation.fulfill()
        })
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testCompletingUpdatingWithSalePriceHigherThanRegularPrice() {
        let product = MockProduct().product()
        let viewModel = ProductPriceSettingsViewModel(product: product)

        let regularPrice = "12"
        let salePrice = "16"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (_, _, _, _, _, _) in
            XCTFail("Completion block should not be called")
        }, onError: { error in
            XCTAssertEqual(error, .salePriceHigherThanRegularPrice)
            expectation.fulfill()
        })
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testCompletingUpdatingWithZeroSalePrice() {
        let product = MockProduct().product()
        let viewModel = ProductPriceSettingsViewModel(product: product)

        let regularPrice = "12"
        let salePrice = "0"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (finalRegularPrice, finalSalePrice, _, _, _, _) in
            XCTAssertEqual(finalRegularPrice, regularPrice)
            XCTAssertEqual(finalSalePrice, salePrice)
            expectation.fulfill()
        }, onError: { error in
            XCTFail("Completion block should not be called")
        })
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // `hasUnsavedChanges`

    func testUnsavedChangesWithDecimalPrices() {
        // TODO-jc: wait until the CurrencySettings can be DI'ed to CurrencyFormatter

        let originalRegularPrice = "12.0"
        let originalSalePrice = "0.5"
        let product = MockProduct().product(regularPrice: originalRegularPrice, salePrice: originalSalePrice)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.regularPrice, originalRegularPrice)
        XCTAssertEqual(viewModel.salePrice, originalSalePrice)

        viewModel.handleRegularPriceChange("12.00")
        viewModel.handleSalePriceChange("0.5000")
        XCTAssertFalse(viewModel.hasUnsavedChanges())

        viewModel.handleRegularPriceChange("12.05")
        viewModel.handleSalePriceChange("0.500")
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testUnsavedChangesWithDefaultTaxClass() {
        let product = MockProduct().product(taxClass: "")
        let viewModel = ProductPriceSettingsViewModel(product: product)
        // Defaults to the standard tax class.
        XCTAssertEqual(viewModel.taxClass?.slug, "standard")
        XCTAssertFalse(viewModel.hasUnsavedChanges())

        let taxClass = TaxClass(siteID: 18, name: "Lowest tax", slug: "nice-tax-class")
        viewModel.handleTaxClassChange(taxClass)
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }
}
