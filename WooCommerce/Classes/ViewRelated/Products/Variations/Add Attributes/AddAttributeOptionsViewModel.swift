import Foundation
import Yosemite

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeOptionsViewModel {

    /// Defines the necessary state to produce the ViewModel's outputs.
    ///
    private struct State {
        /// Stores the options to be offered
        ///
        var optionsOffered: [String] = []
    }

    typealias Section = AddAttributeOptionsViewController.Section
    typealias Row = AddAttributeOptionsViewController.Row

    var titleView: String? {
        newAttributeName ?? attribute?.name
    }
    private(set) var newAttributeName: String?
    private(set) var attribute: ProductAttribute?

    /// Current `ViewModel` state.
    ///
    private var state: State = State() {
        didSet {
            updateSections()
            onChange?()
        }
    }

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

    private(set) var sections: [Section] = []

    init(newAttribute: String?) {
        self.newAttributeName = newAttribute
        updateSections()
    }

    init(existingAttribute: ProductAttribute) {
        self.attribute = existingAttribute
        updateSections()
    }
}

// MARK: - ViewController Inputs
extension AddAttributeOptionsViewModel {
    func addNewOption(name: String) {
        state.optionsOffered.append(name)
    }
}

// MARK: - Synchronize Product Attribute terms
//
private extension AddAttributeOptionsViewModel {
    // TODO: to be implemented - fetch of terms

    /// Updates data in sections
    ///
    func updateSections() {
        let textFieldSection = Section(header: nil, footer: Localization.footerTextField, rows: [.termTextField])
        let offeredSection = createOfferedSection()
        sections = [textFieldSection, offeredSection].compactMap { $0 }
    }

    func createOfferedSection() -> Section? {
        guard state.optionsOffered.isNotEmpty else {
            return nil
        }

        let rows = state.optionsOffered.map { option in
            AddAttributeOptionsViewModel.Row.selectedTerms(name: option)
        }

        return Section(header: Localization.headerSelectedTerms, footer: nil, rows: rows)
    }
}

private extension AddAttributeOptionsViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Add each option and press enter",
                                                       comment: "Footer of text field section in Add Attribute Options screen")
        static let headerSelectedTerms = NSLocalizedString("OPTIONS OFFERED",
                                                           comment: "Header of selected attribute options section in Add Attribute Options screen")
        static let headerExistingTerms = NSLocalizedString("ADD OPTIONS",
                                                           comment: "Header of existing attribute options section in Add Attribute Options screen")
    }
}
