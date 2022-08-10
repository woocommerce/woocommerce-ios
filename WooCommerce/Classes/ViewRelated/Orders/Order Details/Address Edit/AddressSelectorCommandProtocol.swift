//import Foundation
//import Yosemite
//// Why import these 2 like this? Don't we import the whole thing already?
////import struct Yosemite.Country
////import struct Yosemite.StateOfACountry
//import SwiftUI
//
////protocol ItemType {
////    associatedtype Item
////    var item: Item { get set }
////}
//
//final class CommonSelectorCommand: ObservableListSelectorCommand {
//
//    // This needs to accept both Country and StateOfCountry. How to?
//    //typealias Model = Country & StateOfACountry // CombinedType
//    /*
//     Non-protocol, non-class type 'Country' & 'StateOfACountry' cannot be used within a protocol-constrained type
//     */
//    typealias Model = Any
//    typealias Cell = BasicTableViewCell
//
//    var navigationBarTitle: String?
//
//    var data: [Any] = []
//
//    var selected: Any?
//
//    func handleSelectedChange(selected: Any, viewController: ViewController) {
//        <#code#>
//    }
//
//    func isSelected(model: Any) -> Bool {
//        <#code#>
//    }
//
//    func configureCell(cell: BasicTableViewCell, model: Any) {
//        <#code#>
//    }
//
//
//
//
//}
//
////
/////// Command to be used to select a country when editing addresses.
///////
/////// Similar to BottomSheetListSelectorViewController
////final class TestCommonClass<Command: ObservableListSelectorCommand, Model, Cell>: ViewController, UITableViewDataSource, UITableViewDelegate where Command.Model == Model, Command.Cell == Cell {
////
////    // Protocol not really as we're implementing the functions the same way, so we still have to implement them twice. An unique class kinda makes more sense.
////
////    // How should I initialize this typealias? I cannot make it conform to typealias.
////    //lazy var countryOrState: Model = Country
////
////    typealias Model = Country // Podria ser un enum import Yosemite.ShippingLabelPaperSize
////    typealias Cell = BasicTableViewCell // ok
////
////    private let model: Model
////    private let cell: Cell
////    private let code: String? // Only Country has Country.code
////
////    init(model: Model, cell: Cell) {
////        self.model = model
////        self.cell = cell
////    }
////
////    // Original array of countries/states.
////    private let itemsInModel: [Model]
////
////    /// Data to display
////    ///
////    @Published private(set) var dataInModel: [Model]
////
////    /// Current selected country
////    ///
////    @Binding private(set) var selectedModel: Model?
////
////    /// Navigation bar title
////    ///
////    let navigationBarTitle: String? = ""
////
////    // WIP, discard.
////    internal var selected: Model?
////    private var _selected: Binding<Model>?
////
////    // init for both, inject either Country or StateOfACountry in itemsInModel
////    init(itemsInModel: [Model], selected: Binding<Model?>) {
////        self.itemsInModel = itemsInModel
////        self.dataInModel = itemsInModel
////        //self._selected = selected
////        // Value of type 'TestCommonClass' has no member '_selected' . Internal/Private somewhere else?
////    }
////
////    func handleSelectedChange(selected: Model, viewController: ViewController) {
////        self.selected = selected
////        viewController.navigationController?.popViewController(animated: true)
////    }
////
////    func isSelected(model: Model) -> Bool {
////        if self.code != nil {
////            // I'm only comparing country codes because states can be unsorted
////            model == selected?.code
////        } else {
////            model == selected
////        }
////    }
////
////    func configureCell(cell: BasicTableViewCell, model: Model) {
////        cell.textLabel?.text = model.name
////    }
////
////    /// Filter available countries that contains a given search term.
////    ///
////    func filterCountries(term: String) {
////        guard term.isNotEmpty else {
////            return data = countries
////        }
////
////        // Trim the search term to remove newlines or whitespaces (e.g added from the keyboard predictive text) from both ends
////        data = countries.filter { $0.name.localizedCaseInsensitiveContains(term.trim()) }
////    }
////
////}
////
////protocol AddressSelectorCommandProtocol {
////    typealias Model = AnyObject // Wrong
////    typealias Cell = BasicTableViewCell
////    typealias ViewController = AnyObject // Wrong
////    // Data to display
////    // private(set) cannot be used in protocols
////    // cannot have a wrapper either
////    //@Published private(set) var data { get }
//////    @Published var data {
//////        var data: [Model] { get }
//////        mutating func changeValue(to: [Model])
//////    }
////
////    /// Navigation bar title
////    ///
////    var navigationBarTitle: String { get }
////
////    func handleSelectedChange(selected: Model, viewController: ViewController)
////
////    func configureCell(cell: Cell, model: Model)
////
////    func filterData(term: String)
////
////}
////
//////class TestSelectorCommand: AddressSelectorCommandProtocol {
//////    var navigationBarTitle: String = ""
//////
//////    func handleSelectedChange(selected: Model, viewController: ViewController) {
//////        //self.selected = selected
//////        // Value of type 'TestSelectorCommand' has no member 'selected'
//////        viewController.navigationController?.popViewController(animated: true)
//////    }
//////
//////    func configureCell(cell: Cell, model: Model) {
//////        cell.textLabel?.text = model.name
//////    }
//////
//////    func filterData(term: String) {
//////        <#code#>
//////    }
//////
//////
//////}
