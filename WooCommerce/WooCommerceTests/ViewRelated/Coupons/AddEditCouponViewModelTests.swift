import XCTest
import Combine
@testable import Yosemite
@testable import WooCommerce

final class AddEditCouponViewModelTests: XCTestCase {

    func test_titleView_property_return_expected_values_on_creation() {
        let viewModel1 = AddEditCouponViewModel(siteID: 123, discountType: .percent, onSuccess: { _ in })
        XCTAssertEqual(viewModel1.title, NSLocalizedString("Create coupon", comment: ""))
    }

    func test_titleView_property_return_expected_values_on_editing() {
        let viewModel1 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .percent), onSuccess: { _ in })
        XCTAssertEqual(viewModel1.title, NSLocalizedString("Edit coupon", comment: ""))
    }

    func test_generateRandomCouponCode_populate_correctly_the_codeField() {
        // Given
        let viewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(code: ""), onSuccess: { _ in })
        XCTAssertEqual(viewModel.codeField, "")

        // When
        viewModel.generateRandomCouponCode()

        // Then
        let dictionary = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        XCTAssertEqual(viewModel.codeField.count, 8)
        XCTAssertTrue(viewModel.codeField.allSatisfy(dictionary.contains))

    }

    func test_populatedCoupon_return_expected_coupon_during_editing() {
        // Given
        let timeZone = TimeZone.current
        let expiryDate = Date().startOfDay(timezone: timeZone)
        let viewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .percent, dateExpires: expiryDate),
                                               timezone: timeZone,
                                               onSuccess: { _ in })
        assertEqual(viewModel.populatedCoupon, Coupon.sampleCoupon.copy(discountType: .percent,
                                                                        dateExpires: expiryDate))

        // When
        viewModel.amountField = "24.23"
        viewModel.codeField = "TEST"
        viewModel.descriptionField = "This is a test description"
        viewModel.expiryDateField = Date().endOfDay(timezone: timeZone)
        viewModel.freeShipping = true
        viewModel.productOrVariationIDs = [10, 50]
        viewModel.categoryIDs = [3, 9, 44]
        viewModel.couponRestrictionsViewModel.minimumSpend = "10"
        viewModel.couponRestrictionsViewModel.maximumSpend = "50"
        viewModel.couponRestrictionsViewModel.usageLimitPerCoupon = "40"
        viewModel.couponRestrictionsViewModel.usageLimitPerUser = "1"
        viewModel.couponRestrictionsViewModel.limitUsageToXItems = "10"
        viewModel.couponRestrictionsViewModel.allowedEmails = "*@gmail.com, *@wordpress.com"
        viewModel.couponRestrictionsViewModel.individualUseOnly = true
        viewModel.couponRestrictionsViewModel.excludeSaleItems = true
        viewModel.couponRestrictionsViewModel.excludedProductOrVariationIDs = [11, 30]
        viewModel.couponRestrictionsViewModel.excludedCategoryIDs = [4, 10]


        // Then
        assertEqual(viewModel.populatedCoupon, Coupon.sampleCoupon.copy(code: "TEST",
                                                                        amount: "24.23",
                                                                        discountType: .percent,
                                                                        description: "This is a test description",
                                                                        dateExpires: expiryDate,
                                                                        individualUse: true,
                                                                        productIds: [10, 50],
                                                                        excludedProductIds: [11, 30],
                                                                        usageLimit: 40,
                                                                        usageLimitPerUser: 1,
                                                                        limitUsageToXItems: 10,
                                                                        freeShipping: true,
                                                                        productCategories: [3, 9, 44],
                                                                        excludedProductCategories: [4, 10],
                                                                        excludeSaleItems: true,
                                                                        minimumAmount: "10",
                                                                        maximumAmount: "50",
                                                                        emailRestrictions: ["*@gmail.com", "*@wordpress.com"]))
    }

    func test_populatedCoupon_return_expected_coupon_during_creation() {
        // Given
        let viewModel = AddEditCouponViewModel(siteID: 0, discountType: .fixedCart, onSuccess: { _ in })

        // When
        let populatedCoupon = viewModel.populatedCoupon
        let newCoupon = Coupon(couponID: -1,
                               code: populatedCoupon.code,
                               amount: "",
                               dateCreated: populatedCoupon.dateCreated,
                               dateModified: populatedCoupon.dateModified,
                               discountType: .fixedCart,
                               description: "",
                               dateExpires: nil,
                               usageCount: 0,
                               individualUse: false,
                               productIds: [],
                               excludedProductIds: [],
                               usageLimit: nil,
                               usageLimitPerUser: nil,
                               limitUsageToXItems: nil,
                               freeShipping: false,
                               productCategories: [],
                               excludedProductCategories: [],
                               excludeSaleItems: false,
                               minimumAmount: "",
                               maximumAmount: "",
                               emailRestrictions: [],
                               usedBy: [])

        // Then
        XCTAssertEqual(populatedCoupon, newCoupon)
    }

    func test_validateCouponLocally_return_expected_error_if_coupon_code_is_empty() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(code: "")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })

        // When
        let result = viewModel.validateCouponLocally(coupon)

        // Then
        XCTAssertEqual(result, AddEditCouponViewModel.CouponError.couponCodeEmpty)
    }

    func test_validateCouponLocally_return_nil_if_coupon_code_is_not_empty() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(code: "ABCDEF")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })

        // When
        let result = viewModel.validateCouponLocally(coupon)

        // Then
        XCTAssertNil(result)
    }

    func test_hasChangesMade_is_correct_for_discount_type() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(discountType: .percent)
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.discountType = .fixedProduct

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_coupon_code() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(code: "ABCDEF")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.codeField = "1d23rds3"

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_amount() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "11.22")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.amountField = "10.00"

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_expiry_date() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(dateExpires: Date())
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.expiryDateField = Date().adding(days: 12, seconds: 0, using: .current)

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_nil_expiry_date() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(dateExpires: Date())
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.expiryDateField = nil

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_updated_product_restrictions() {
        // Given
        let coupon = Coupon.sampleCoupon
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.productOrVariationIDs = [1, 21, 33]

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_updated_category_restrictions() {
        // Given
        let coupon = Coupon.sampleCoupon
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.categoryIDs = [12, 2]

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_description() {
        // Given
        let coupon = Coupon.sampleCoupon
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.descriptionField = "lorem ipsum"

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_free_shipping() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(freeShipping: false)
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.freeShipping = true

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_correct_for_updated_usage_restrictions() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(usageLimit: 100)
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })
        XCTAssertFalse(viewModel.hasChangesMade) // confidence check

        // When
        viewModel.couponRestrictionsViewModel.usageLimitPerCoupon = "1000"

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }

    func test_hasChangesMade_is_always_true_when_is_in_creation_mode() {
        // Given
        let viewModel = AddEditCouponViewModel(siteID: 123, discountType: .percent, onSuccess: {_ in })

        // Then
        XCTAssertTrue(viewModel.hasChangesMade)
    }
    
    func test_validatePercentageAmountInput_correctly_control_warning_visibility() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "20000", discountType: .percent)
        let viewModel = AddEditCouponViewModel(
                existingCoupon: coupon,
                inputWarningDurationInSeconds: 0.1,
                onSuccess: { _ in }
        )
        XCTAssertFalse(viewModel.isDisplayingAmountWarning)

        // When
        viewModel.validatePercentageAmountInput(withWarning: true)

        // Then
        XCTAssertTrue(viewModel.isDisplayingAmountWarning)

        waitFor { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                promise(())
            }
        }

        XCTAssertFalse(viewModel.isDisplayingAmountWarning)
    }
    
    func test_validatePercentageAmountInput_returns_error_for_invalid_amount() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "invalid", discountType: .percent)
        let viewModel = AddEditCouponViewModel(
                existingCoupon: coupon,
                inputWarningDurationInSeconds: 0.1,
                onSuccess: { _ in }
        )

        // When
        let error = viewModel.validatePercentageAmountInput(withWarning: true)

        // Then
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .couponPercentAmountInvalid)
    }

    func test_validatePercentAmountInput_returns_nil_when_set_for_warning_correction() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "200", discountType: .percent)
        let viewModel = AddEditCouponViewModel(
                existingCoupon: coupon,
                inputWarningDurationInSeconds: 0.1,
                onSuccess: { _ in }
        )

        // When
        let error = viewModel.validatePercentageAmountInput(withWarning: true)

        // Then
        XCTAssertNil(error)
    }
    
    func test_validatePercentageAmountInput_returns_error_when_set_for_no_warning() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "200", discountType: .percent)
        let viewModel = AddEditCouponViewModel(
                existingCoupon: coupon,
                inputWarningDurationInSeconds: 0.1,
                onSuccess: { _ in }
        )

        // When
        let error = viewModel.validatePercentageAmountInput(withWarning: false)

        // Then
        XCTAssertNotNil(error)
        XCTAssertEqual(error, .couponPercentAmountInvalid)
    }

    func test_validatePercentageAmountInput_with_no_warning_defaults_amount_to_zero() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "invalid", discountType: .percent)
        let viewModel = AddEditCouponViewModel(
                existingCoupon: coupon,
                inputWarningDurationInSeconds: 0.1,
                onSuccess: { _ in }
        )

        // When
        let error = viewModel.validatePercentageAmountInput(withWarning: false)

        // Then
        XCTAssertEqual(viewModel.amountField, "0")
    }
    
    func test_validatePercentageAmountInput_ignores_validation_when_discountType_is_not_percent() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "200", discountType: .fixedCart)
        let viewModel = AddEditCouponViewModel(
                existingCoupon: coupon,
                inputWarningDurationInSeconds: 0.1,
                onSuccess: { _ in }
        )

        // When
        let error = viewModel.validatePercentageAmountInput(withWarning: false)

        // Then
        XCTAssertNil(error)
        XCTAssertEqual(viewModel.amountField, "200")
    }
    
    func test_validatePercentageAmountInput_returns_nil_if_amount_is_valid() {
        
    }

    func test_discount_type_changed_to_percent_triggers_amount_adjustment() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "20000")
        let viewModel = AddEditCouponViewModel(
            existingCoupon: coupon,
            inputWarningDurationInSeconds: 0.01,
            onSuccess: { _ in }
        )

        // When
        viewModel.discountType = .percent

        waitFor { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                promise(())
            }
        }

        XCTAssertEqual(viewModel.amountField, "100")
    }

    func test_discount_type_changed_to_percent_doesnt_convert_valid_amount() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "99.9")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })

        // When
        viewModel.discountType = .percent

        // Then
        XCTAssertEqual(viewModel.amountField, "99.9")
    }

    func test_discount_type_changed_to_percent_converts_invalid_amount_to_zero() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(amount: "invalid")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon, onSuccess: { _ in })

        // When
        viewModel.discountType = .percent

        // Then
        XCTAssertEqual(viewModel.amountField, "0")
    }
}
