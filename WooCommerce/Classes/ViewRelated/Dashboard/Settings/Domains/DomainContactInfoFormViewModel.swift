import Combine
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `DomainContactInfoForm`.
final class DomainContactInfoFormViewModel: AddressFormViewModel, AddressFormViewModelProtocol {
    let siteID: Int64
    private let domain: String

    private var contactInfo: DomainContactInfo {
        let phone: String = {
            // The user can enter characters like `-` or `.` into the field, and the API expects digits only.
            let countryCode = fields.phoneCountryCode.filter { $0.isNumber }
            let number = fields.phone.filter { $0.isNumber }
            return "\(Constants.phoneNumberPrefix)\(countryCode)\(Constants.phoneNumberSeparator)\(number)"
        }()
        return .init(firstName: fields.firstName,
              lastName: fields.lastName,
              organization: fields.company,
              address1: fields.address1,
              address2: fields.address2,
              postcode: fields.postcode,
              city: fields.city,
              state: fields.selectedState?.code ?? "",
              countryCode: fields.selectedCountry?.code ?? "",
              phone: phone,
              email: fields.email)
    }

    init(siteID: Int64,
         contactInfoToEdit: DomainContactInfo?,
         domain: String,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.domain = domain

        let (addressToEdit, phoneCountryCode): (Address, String?) = {
            guard let contactInfoToEdit else {
                return (.empty, nil)
            }

            let (phoneCountryCode, phoneNumber): (String?, String?) = {
                // The phone number in the contact info API is in the format of `+\(countryCode).\(phoneNumber)`.
                let phoneParts = contactInfoToEdit.phone?
                    .replacingOccurrences(of: Constants.phoneNumberPrefix, with: "")
                    .split(separator: Constants.phoneNumberSeparator)
                guard let phoneParts, phoneParts.count == 2 else {
                    return (nil, nil)
                }
                return (String(phoneParts[0]), String(phoneParts[1]))
            }()
            return (.init(firstName: contactInfoToEdit.firstName,
                          lastName: contactInfoToEdit.lastName,
                          company: contactInfoToEdit.organization,
                          address1: contactInfoToEdit.address1,
                          address2: contactInfoToEdit.address2,
                          city: contactInfoToEdit.city,
                          state: contactInfoToEdit.state ?? "",
                          postcode: contactInfoToEdit.postcode,
                          country: contactInfoToEdit.countryCode,
                          phone: phoneNumber,
                          email: contactInfoToEdit.email), phoneCountryCode)
        }()

        super.init(siteID: siteID,
                   address: addressToEdit,
                   phoneCountryCode: phoneCountryCode ?? "",
                   isDoneButtonAlwaysEnabled: true,
                   storageManager: storageManager,
                   stores: stores,
                   analytics: analytics)
    }

    /// Validates and returns the contact info on success.
    /// - Returns: Contact info after it is validated remotely.
    @MainActor
    func validateContactInfo() async throws -> DomainContactInfo {
        guard fields.email.isNotEmpty, validateEmail() else {
            notice = AddressFormViewModel.NoticeFactory.createInvalidEmailNotice()
            throw ContactInfoError.invalidEmail
        }

        do {
            try await validate()
            return contactInfo
        } catch DomainContactInfoError.invalid(let messages) {
            let message = messages?.joined(separator: "\n") ?? Localization.defaultValidationErrorMessage
            notice = .init(title: Localization.validationErrorTitle, message: message, feedbackType: .error)
            throw DomainContactInfoError.invalid(messages: messages)
        } catch {
            notice = .init(title: error.localizedDescription, feedbackType: .error)
            throw error
        }
    }

    // MARK: - Protocol conformance

    /// Email is a required field for domain contact info.
    let showEmailField: Bool = true

    /// Phone country code is a required field for domain contact info.
    let showPhoneCountryCodeField: Bool = true

    let viewTitle: String = Localization.title

    let sectionTitle: String = Localization.addressSection

    let secondarySectionTitle: String = ""

    let showAlternativeUsageToggle: Bool = false

    let alternativeUsageToggleTitle: String? = nil

    let showDifferentAddressToggle: Bool = false

    let differentAddressToggleTitle: String? = nil

    func saveAddress(onFinish: @escaping (Bool) -> Void) {
        fatalError("Please call `validateContactInfo` instead.")
    }

    override func trackOnLoad() {
        // TODO: 8558 - analytics
    }

    func userDidCancelFlow() {
        // TODO: 8558 - analytics
    }
}

private extension DomainContactInfoFormViewModel {
    @MainActor
    func validate() async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.validate(domainContactInfo: contactInfo, domain: domain) { result in
                continuation.resume(with: result)
            })
        }
    }
}

private extension DomainContactInfoFormViewModel {
    enum ContactInfoError: Error {
        case invalidEmail
    }
}

private extension DomainContactInfoFormViewModel {
    // MARK: Constants
    enum Localization {
        static let title = NSLocalizedString("Register domain", comment: "Title of the domain contact info form.")
        static let addressSection = NSLocalizedString("ADDRESS", comment: "Address section title in the domain contact info form.")
        static let validationErrorTitle = NSLocalizedString(
            "Form Validation Error",
            comment: "Title in the error notice when a validation error occurs after submitting domain contact info."
        )
        static let defaultValidationErrorMessage = NSLocalizedString(
            "Some unexpected error with the validation. Please check the fields and try again.",
            comment: "Message in the error notice when an unknown validation error occurs after submitting domain contact info."
        )
    }

    enum Constants {
        static let phoneNumberPrefix: String = "+"
        static let phoneNumberSeparator: Character = "."
    }
}
