import Combine
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `DomainContactInfoForm`.
final class DomainContactInfoFormViewModel: AddressFormViewModel, AddressFormViewModelProtocol {
    let siteID: Int64

    private var contactInfo: DomainContactInfo {
        .init(firstName: fields.firstName,
              lastName: fields.lastName,
              organization: fields.company,
              address1: fields.address1,
              address2: fields.address2,
              postcode: fields.postcode,
              city: fields.city,
              state: fields.selectedState?.code ?? "",
              countryCode: fields.selectedCountry?.code ?? "",
              phone: fields.phone,
              email: fields.email)
    }

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID

        super.init(siteID: siteID,
                   address: .empty,
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

        // TODO: 8558 - validate contact info remotely

        return contactInfo
    }

    // MARK: - Protocol conformance

    /// Email is a required field for domain contact info.
    let showEmailField: Bool = true

    let viewTitle: String = Localization.title

    let sectionTitle: String = Localization.addressSection

    var secondarySectionTitle: String = ""

    var showAlternativeUsageToggle: Bool = false

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
    enum ContactInfoError: Error {
        case invalidEmail
    }
}

private extension DomainContactInfoFormViewModel {
    // MARK: Constants
    enum Localization {
        static let title = NSLocalizedString("Register domain", comment: "Title of the domain contact info form.")
        static let addressSection = NSLocalizedString("ADDRESS", comment: "Address section title in the domain contact info form.")
    }
}
