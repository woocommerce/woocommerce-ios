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
        // Arrange
        let regularPrice = "3.6"
        let product = MockProduct().product(regularPrice: regularPrice)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.regularPrice, regularPrice)

        // Act
        viewModel.handleRegularPriceChange(nil)

        // Assert
        XCTAssertEqual(viewModel.regularPrice, nil)
    }

    func testHandlingNonNilRegularPrice() {
        // Arrange
        let product = MockProduct().product(regularPrice: nil)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.regularPrice, nil)

        // Act
        let regularPrice = "3.6"
        viewModel.handleRegularPriceChange(regularPrice)

        // Assert
        XCTAssertEqual(viewModel.regularPrice, regularPrice)
    }

    // Sale price

    func testHandlingNilSalePrice() {
        // Arrange
        let salePrice = "3.6"
        let product = MockProduct().product(salePrice: salePrice)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.salePrice, salePrice)

        // Act
        viewModel.handleSalePriceChange(nil)

        // Assert
        XCTAssertEqual(viewModel.salePrice, nil)
    }

    func testHandlingNonNilSalePrice() {
        // Arrange
        let product = MockProduct().product(salePrice: nil)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.salePrice, nil)

        // Act
        let salePrice = "3.6"
        viewModel.handleSalePriceChange(salePrice)

        // Assert
        XCTAssertEqual(viewModel.salePrice, salePrice)
    }

    // Tax class

    func testHandlingNilTaxClass() {
        // Arrange
        let originalTaxClass = "zero"
        let product = MockProduct().product(taxClass: originalTaxClass)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxClass?.slug, originalTaxClass)

        // Act
        viewModel.handleTaxClassChange(nil)

        // Assert
        XCTAssertEqual(viewModel.taxClass, nil)
    }

    func testHandlingNonNilTaxClass() {
        // Arrange
        let originalTaxClass = "zero"
        let product = MockProduct().product(taxClass: originalTaxClass)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxClass?.slug, originalTaxClass)

        // Act
        let taxClass = TaxClass(siteID: 18, name: "Lowest tax", slug: "nice-tax-class")
        viewModel.handleTaxClassChange(taxClass)

        // Assert
        XCTAssertEqual(viewModel.taxClass?.slug, taxClass.slug)
    }

    // Tax status

    func testHandlingTaxStatus() {
        // Arrange
        let originalTaxStatus = ProductTaxStatus.shipping
        let product = MockProduct().product(taxStatus: originalTaxStatus)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.taxStatus, originalTaxStatus)

        // Act
        let taxStatus = ProductTaxStatus.taxable
        viewModel.handleTaxStatusChange(taxStatus)

        // Assert
        XCTAssertEqual(viewModel.taxStatus, taxStatus)
    }

    // Schedule sale toggle

    func testHandlingDisabledScheduleSale() {
        // Arrange
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-28T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        viewModel.handleScheduleSaleChange(isEnabled: false)

        // Assert
        XCTAssertEqual(viewModel.dateOnSaleStart, nil)
        XCTAssertEqual(viewModel.dateOnSaleEnd, nil)
    }

    func testHandlingEnabledScheduleSaleFromNilSaleDates() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let product = MockProduct().product(dateOnSaleStart: nil, dateOnSaleEnd: nil)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, nil)
        XCTAssertEqual(viewModel.dateOnSaleEnd, nil)

        // Act
        let expectedSaleStartDate = Date().startOfDay(timezone: timezone)
        let expectedSaleEndDate = Calendar.current.date(byAdding: .day, value: 1, to: Date().endOfDay(timezone: timezone))
        viewModel.handleScheduleSaleChange(isEnabled: true)

        // Assert
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedSaleEndDate)
    }

    func testHandlingEnabledScheduleSaleFromExistingSaleDates() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-28T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        viewModel.handleScheduleSaleChange(isEnabled: true)

        // Assert
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)
    }

    // Sale start date

    // TODO-2020: support sale dates without an end date
    /*
    func testHandlingSaleStartDateWithoutSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate: Date? = nil
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-20T21:30:00")!
        viewModel.handleSaleStartDateChange(saleStartDate)

        // Assert
        XCTAssertEqual(viewModel.dateOnSaleStart, saleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)
    }
    */

    func testHandlingSaleStartDateWithAnEarlierSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-18T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-20T21:30:00")!
        viewModel.handleSaleStartDateChange(saleStartDate)

        // Assert
        let expectedStartDate = saleStartDate.startOfDay(timezone: timezone)
        let expectedEndDate = saleStartDate.endOfDay(timezone: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleStartDateWithALaterSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-18T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-16T21:30:00")!
        viewModel.handleSaleStartDateChange(saleStartDate)

        // Assert
        let expectedStartDate = saleStartDate.startOfDay(timezone: timezone)
        let expectedEndDate = originalSaleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // Sale end date

    // TODO-2020: support sale dates without a start date
    /*
    func testHandlingSaleEndDateWithoutSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate: Date? = nil
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-15T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-10-20T21:30:00")!
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        let expectedStartDate: Date? = nil
        let expectedEndDate = saleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }
    */

    func testHandlingSaleEndDateWithAnEarlierSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-27T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-20T21:30:00")!
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        let expectedStartDate = originalSaleStartDate
        let expectedEndDate = saleEndDate.endOfDay(timezone: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleEndDateWithALaterSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-27T21:30:00")
        let product = MockProduct().product(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let viewModel = ProductPriceSettingsViewModel(product: product, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleEndDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-09-01T21:30:00")!
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        let expectedStartDate = originalSaleStartDate
        let expectedEndDate = originalSaleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // MARK: - Navigation actions

    // `completeUpdating`

    func testCompletingUpdatingWithSalePriceOnly() {
        // Arrange
        let product = MockProduct().product()
        let viewModel = ProductPriceSettingsViewModel(product: product)

        // Act
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

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testCompletingUpdatingWithSalePriceHigherThanRegularPrice() {
        // Arrange
        let product = MockProduct().product()
        let viewModel = ProductPriceSettingsViewModel(product: product)

        // Act
        let regularPrice = "12"
        let salePrice = "16"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (_, _, _, _, _, _) in
            XCTFail("Completion block should not be called")
        }, onError: { error in
            // Assert
            XCTAssertEqual(error, .salePriceHigherThanRegularPrice)
            expectation.fulfill()
        })
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
    
    func testCompletingUpdatingWithZeroSalePrice() {
        // Arrange
        let product = MockProduct().product()
        let viewModel = ProductPriceSettingsViewModel(product: product)

        // Act
        let regularPrice = "12"
        let salePrice = "0"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (finalRegularPrice, finalSalePrice, _, _, _, _) in
            expectation.fulfill()

            // Assert
            XCTAssertEqual(finalRegularPrice, regularPrice)
            XCTAssertEqual(finalSalePrice, salePrice)
        }, onError: { error in
            XCTFail("Completion block should not be called")
        })
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // `hasUnsavedChanges`

    func testUnsavedChangesWithDecimalPrices() {
        // Arrange
        let currencySettings = CurrencySettings(currencyCode: .TWD, currencyPosition: .left, thousandSeparator: ",", decimalSeparator: ".", numberOfDecimals: 2)

        let originalRegularPrice = "12.0"
        let originalSalePrice = "0.5"
        let product = MockProduct().product(regularPrice: originalRegularPrice, salePrice: originalSalePrice)
        let viewModel = ProductPriceSettingsViewModel(product: product, currencySettings: currencySettings)
        XCTAssertEqual(viewModel.regularPrice, originalRegularPrice)
        XCTAssertEqual(viewModel.salePrice, originalSalePrice)

        // Act 1
        viewModel.handleRegularPriceChange("12.00")
        viewModel.handleSalePriceChange("0.5000")
        // Assert 1
        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // Act 2
        viewModel.handleRegularPriceChange("12.05")
        viewModel.handleSalePriceChange("0.500")
        // Assert 2
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testUnsavedChangesWithDefaultTaxClass() {
        // Arrange
        let product = MockProduct().product(taxClass: "")
        let viewModel = ProductPriceSettingsViewModel(product: product)
        // Defaults to the standard tax class.
        XCTAssertEqual(viewModel.taxClass?.slug, "standard")
        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // Act
        let taxClass = TaxClass(siteID: 18, name: "Lowest tax", slug: "nice-tax-class")
        viewModel.handleTaxClassChange(taxClass)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }
}
