import Foundation
import Yosemite

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeOptionsViewModel {
    typealias Section = AddAttributeOptionsViewController.Section
    typealias Row = AddAttributeOptionsViewController.Row

    /// Defines the necessary state to produce the ViewModel's outputs.
    ///
    private struct State {
        /// Stores the options to be offered
        ///
        var optionsOffered: [String] = []
    }

    /// Title of the navigation bar
    ///
    var titleView: String? {
        newAttributeName ?? attribute?.name
    }

    /// Defines next button visibility
    ///
    var isNextButtonEnabled: Bool {
        state.optionsOffered.isNotEmpty
    }

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

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
        let textFieldSection = Section(header: nil, footer: Localization.footerTextField, rows: [.termTextField], allowsReorder: false)
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

        return Section(header: Localization.headerSelectedTerms, footer: nil, rows: rows, allowsReorder: true)
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
