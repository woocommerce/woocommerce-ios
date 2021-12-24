import Combine
import Yosemite
import protocol Storage.StorageManagerType

/// Protocol to describe viewmodel of editable address
///
protocol AddressFormViewModelProtocol: ObservableObject {

    /// Address form fields
    ///
    var fields: AddressFormViewModel.FormFields { get set }

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    var navigationTrailingItem: AddressFormViewModel.NavigationItem { get }

    /// Trigger to perform any one time setups.
    ///
    var onLoadTrigger: PassthroughSubject<Void, Never> { get }

    /// Define if the view should show placeholders instead of the real elements.
    ///
    var showPlaceholders: Bool { get }

    /// Defines if the state field should be defined as a list selector.
    ///
    var showStateFieldAsSelector: Bool { get }

    /// Defines if the email field should be shown
    ///
    var showEmailField: Bool { get }

    /// Defines navbar title
    ///
    var viewTitle: String { get }

    /// Defines address section title
    ///
    var sectionTitle: String { get }

    /// Defines bottom toggle title
    ///
    var toggleTitle: String { get }

    /// Save the address and invoke a completion block when finished
    ///
    func saveAddress(onFinish: @escaping (Bool) -> Void)

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow()

    /// Creates a view model to be used when selecting a country
    ///
    func createCountryViewModel() -> CountrySelectorViewModel

    /// Creates a view model to be used when selecting a state
    ///
    func createStateViewModel() -> StateSelectorViewModel
}
