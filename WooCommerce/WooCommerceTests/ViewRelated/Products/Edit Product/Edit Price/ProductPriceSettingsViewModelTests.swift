import XCTest
@testable import WooCommerce
@testable import Yosemite
import WooFoundation

final class ProductPriceSettingsViewModelTests: XCTestCase {
    private let numberOfSecondsPerDay: TimeInterval = 86400

    // MARK: - Initialization

    // Sale dates initialization

    func testInitSaleStartDateWithoutSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let saleStartDate = date(from: "2019-10-15T21:30:00")
        let saleEndDate: Date? = nil
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Assert
        let expectedStartDate = saleStartDate
        let expectedEndDate = saleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testInitSaleEndDateInThePastWithoutSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let saleStartDate: Date? = nil
        let saleEndDate = date(from: "2019-10-15T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Assert
        let expectedStartDate = saleStartDate
        let expectedEndDate = saleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testInitSaleEndDateInTheFutureWithoutSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let saleStartDate: Date? = nil
        let saleEndDate = Date().addingTimeInterval(numberOfSecondsPerDay)
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Assert
        let expectedStartDate = Date().startOfDay(timezone: timezone)
        let expectedEndDate = saleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // `retrieveProductTaxClass`

    func testHandlingNilRetrievedTaxClass() {
        // Arrange
        let mockStoresManager = MockTaxClassStoresManager(missingTaxClass: nil, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let originalTaxClass = "zero"
        let product = Product.fake().copy(taxClass: originalTaxClass)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let product = Product.fake().copy(taxClass: originalTaxClass)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let product = Product.fake().copy(regularPrice: regularPrice)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        XCTAssertEqual(viewModel.regularPrice, regularPrice)

        // Act
        viewModel.handleRegularPriceChange(nil)

        // Assert
        XCTAssertEqual(viewModel.regularPrice, nil)
    }

    func testHandlingNonNilRegularPrice() {
        // Arrange
        let product = Product.fake().copy(regularPrice: nil)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let product = Product.fake().copy(salePrice: salePrice)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        XCTAssertEqual(viewModel.salePrice, salePrice)

        // Act
        viewModel.handleSalePriceChange(nil)

        // Assert
        XCTAssertEqual(viewModel.salePrice, nil)
    }

    func testHandlingNonNilSalePrice() {
        // Arrange
        let product = Product.fake().copy(salePrice: nil)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let product = Product.fake().copy(taxClass: originalTaxClass)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        XCTAssertEqual(viewModel.taxClass?.slug, originalTaxClass)

        // Act
        viewModel.handleTaxClassChange(nil)

        // Assert
        XCTAssertEqual(viewModel.taxClass, nil)
    }

    func testHandlingNonNilTaxClass() {
        // Arrange
        let originalTaxClass = "zero"
        let product = Product.fake().copy(taxClass: originalTaxClass)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let product = Product.fake().copy(taxStatusKey: originalTaxStatus.rawValue)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let originalSaleStartDate = date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = date(from: "2019-10-28T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
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
        let product = Product.fake().copy(dateOnSaleStart: nil, dateOnSaleEnd: nil)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
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
        let originalSaleStartDate = date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = date(from: "2019-10-28T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        viewModel.handleScheduleSaleChange(isEnabled: true)

        // Assert
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)
    }

    // Sale start date

    func testHandlingSaleStartDateWithoutSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate: Date? = nil
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleStartDate = date(from: "2019-10-20T21:30:00")!
        viewModel.handleSaleStartDateChange(saleStartDate)

        // Assert
        let expectedSaleStartDate = saleStartDate.startOfDay(timezone: timezone)
        let expectedSaleEndDate = originalSaleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedSaleEndDate)
    }

    func testHandlingSaleStartDateWithAnEarlierSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = date(from: "2019-10-18T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleStartDate = date(from: "2019-10-20T21:30:00")!
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
        let originalSaleStartDate = date(from: "2019-10-15T21:30:00")
        let originalSaleEndDate = date(from: "2019-10-18T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleStartDate = date(from: "2019-10-16T21:30:00")!
        viewModel.handleSaleStartDateChange(saleStartDate)

        // Assert
        let expectedStartDate = saleStartDate.startOfDay(timezone: timezone)
        let expectedEndDate = originalSaleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // Sale end date

    func testHandlingSaleEndDateInThePastWithoutSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate: Date? = nil
        let originalSaleEndDate = date(from: "2019-10-15T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Act
        let saleEndDate = date(from: "2019-10-20T21:30:00")!
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        let expectedStartDate: Date? = nil
        let expectedEndDate = saleEndDate.endOfDay(timezone: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleEndDateInTheFutureWithoutSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate: Date? = nil
        let originalSaleEndDate = Date().addingTimeInterval(numberOfSecondsPerDay)
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Act
        let saleEndDate = originalSaleEndDate.addingTimeInterval(numberOfSecondsPerDay)
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        let expectedStartDate: Date? = Date().startOfDay(timezone: timezone)
        let expectedEndDate = saleEndDate.endOfDay(timezone: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingSaleEndDateWithAnEarlierSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = date(from: "2019-09-27T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleEndDate = date(from: "2019-09-20T21:30:00")!
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
        let originalSaleStartDate = date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = date(from: "2019-09-27T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        let saleEndDate = date(from: "2019-09-01T21:30:00")!
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        let expectedStartDate = originalSaleStartDate
        let expectedEndDate = originalSaleEndDate
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    func testHandlingNilSaleEndDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = date(from: "2019-09-27T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)
        XCTAssertEqual(viewModel.dateOnSaleStart, originalSaleStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, originalSaleEndDate)

        // Act
        viewModel.handleSaleEndDateChange(nil)

        // Assert
        let expectedStartDate = originalSaleStartDate
        let expectedEndDate: Date? = nil
        XCTAssertEqual(viewModel.dateOnSaleStart, expectedStartDate)
        XCTAssertEqual(viewModel.dateOnSaleEnd, expectedEndDate)
    }

    // MARK: - Navigation actions

    // `completeUpdating`

    func testCompletingUpdatingWithSalePriceOnly() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let regularPrice = ""
        let salePrice = "17"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (_, _, _, _, _, _, _, _, _, _) in
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
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let regularPrice = "12"
        let salePrice = "16"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (_, _, _, _, _, _, _, _, _, _) in
            XCTFail("Completion block should not be called")
        }, onError: { error in
            // Assert
            XCTAssertEqual(error, .salePriceHigherThanRegularPrice)
            expectation.fulfill()
        })
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_completeUpdating_new_sale_with_nil_sale_price() {
        // Arrange
        let dateOnSaleStart = date(from: "2019-09-02T21:30:00")
        let dateOnSaleEnd = date(from: "2019-09-27T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd, salePrice: nil)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let result = waitFor { promise in
            viewModel.completeUpdating { (_, _, _, _, _, _, _, _, _, _) in
                XCTFail("Completion block should not be called")
            } onError: { error in
                promise(error)
            }
        }

        // Assert
        XCTAssertEqual(result, .newSaleWithEmptySalePrice)
    }

    func testCompletingUpdatingWithZeroSalePrice() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let regularPrice = "12"
        let salePrice = "0"
        viewModel.handleRegularPriceChange(regularPrice)
        viewModel.handleSalePriceChange(salePrice)

        let expectation = self.expectation(description: "Wait for error")
        viewModel.completeUpdating(onCompletion: { (finalRegularPrice, _, _, _, finalSalePrice, _, _, _, _, _) in
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
        let product = Product.fake().copy(regularPrice: originalRegularPrice,
                                          salePrice: originalSalePrice,
                                          taxStatusKey: ProductTaxStatus.taxable.rawValue,
                                          taxClass: "")
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, currencySettings: currencySettings)
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
        let product = Product.fake().copy(taxStatusKey: ProductTaxStatus.taxable.rawValue, taxClass: "")
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        // Defaults to the standard tax class.
        XCTAssertEqual(viewModel.taxClass?.slug, "standard")
        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // Act
        let taxClass = TaxClass(siteID: 18, name: "Lowest tax", slug: "nice-tax-class")
        viewModel.handleTaxClassChange(taxClass)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testUnsavedChangesWithSaleEndDateInThePastAndNilSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let saleStartDate: Date? = nil
        let saleEndDate = date(from: "2019-10-15T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate,
                                          dateOnSaleEnd: saleEndDate,
                                          taxStatusKey: ProductTaxStatus.taxable.rawValue,
                                          taxClass: "")
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func testUnsavedChangesWithSaleEndDateInTheFutureAndNilSaleStartDate() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let saleStartDate: Date? = nil
        let saleEndDate = Date().addingTimeInterval(numberOfSecondsPerDay)
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate,
                                          dateOnSaleEnd: saleEndDate,
                                          taxStatusKey: ProductTaxStatus.taxable.rawValue,
                                          taxClass: "")
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    // MARK: - Sections

    typealias Section = ProductPriceSettingsViewModel.Section

    func testInitialSectionsWithoutSaleDates() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate: Date? = nil
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let sections = viewModel.sections

        // Assert
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle, rows: [.salePrice, .scheduleSale]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ]
        XCTAssertEqual(sections, initialSections)
    }

    func test_price_section_includes_subscription_rows_if_product_type_is_subscription() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate: Date? = nil
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate, subscription: .fake())
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let sections = viewModel.sections

        // Assert
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price, .subscriptionPeriod, .subscriptionSignupFee]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle, rows: [.salePrice, .scheduleSale]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ]
        XCTAssertEqual(sections, initialSections)
    }

    func testTappingScheduleSaleFromRowTogglesPickerRowInSalesSection() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate = Date().addingTimeInterval(numberOfSecondsPerDay)
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .removeSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ]
        XCTAssertEqual(viewModel.sections, initialSections)

        // Act
        viewModel.didTapScheduleSaleFromRow()
        let sectionsAfterTheFirstTap = viewModel.sections
        viewModel.didTapScheduleSaleFromRow()
        let sectionsAfterTheSecondTap = viewModel.sections

        // Assert
        XCTAssertEqual(sectionsAfterTheFirstTap, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .datePickerSaleFrom, .scheduleSaleTo, .removeSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ])
        XCTAssertEqual(sectionsAfterTheSecondTap, initialSections)
    }

    func testTappingScheduleSaleToRowTogglesPickerRowInSalesSection() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate = Date().addingTimeInterval(numberOfSecondsPerDay)
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .removeSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ]
        XCTAssertEqual(viewModel.sections, initialSections)

        // Act
        viewModel.didTapScheduleSaleToRow()
        let sectionsAfterTheFirstTap = viewModel.sections
        viewModel.didTapScheduleSaleToRow()
        let sectionsAfterTheSecondTap = viewModel.sections

        // Assert
        XCTAssertEqual(sectionsAfterTheFirstTap, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .datePickerSaleTo, .removeSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ])
        XCTAssertEqual(sectionsAfterTheSecondTap, initialSections)
    }

    func testRemovingSaleEndDateDeletesRemoveSaleToRow() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate = Date().addingTimeInterval(numberOfSecondsPerDay)
        let product = Product.fake().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .removeSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ]
        XCTAssertEqual(viewModel.sections, initialSections)

        // Act
        viewModel.handleSaleEndDateChange(nil)

        // Assert
        XCTAssertEqual(viewModel.sections, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ])
    }

    func test_handling_nonnil_sale_end_date_does_not_hide_date_editing_rows() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = date(from: "2019-09-27T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Act
        viewModel.didTapScheduleSaleToRow()
        let saleEndDate = date(from: "2020-09-20T21:30:00")!
        viewModel.handleSaleEndDateChange(saleEndDate)

        // Assert
        XCTAssertEqual(viewModel.sections, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .datePickerSaleTo, .removeSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ])
    }

    func test_handling_nil_sale_end_date_hides_date_editing_rows() {
        // Arrange
        let timezone = TimeZone(secondsFromGMT: 0)!
        let originalSaleStartDate = date(from: "2019-09-02T21:30:00")
        let originalSaleEndDate = date(from: "2019-09-27T21:30:00")
        let product = Product.fake().copy(dateOnSaleStart: originalSaleStartDate, dateOnSaleEnd: originalSaleEndDate)
        let model = EditableProductModel(product: product)
        let viewModel = ProductPriceSettingsViewModel(product: model, timezoneForScheduleSaleDates: timezone)

        // Act
        viewModel.didTapScheduleSaleToRow()
        viewModel.handleSaleEndDateChange(nil)

        // Assert
        XCTAssertEqual(viewModel.sections, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price]),
            Section(title: ProductPriceSettingsViewModel.Strings.saleSectionTitle,
                    rows: [.salePrice, .scheduleSale, .scheduleSaleFrom, .scheduleSaleTo]),
            Section(title: ProductPriceSettingsViewModel.Strings.taxSectionTitle, rows: [.taxStatus, .taxClass])
        ])
    }
}

private extension ProductPriceSettingsViewModelTests {
    func date(from dateString: String) -> Date? {
        DateFormatter.Defaults.dateTimeFormatter.date(from: dateString)
    }
}
