import Foundation
import SwiftUI

struct SearchView: View {
    let names: [String] = []
    @ObservedObject var viewModel: SearchViewModel
    @State private var searchText = ""
    @State private var selection: String?

    init(viewModel: SearchViewModel = SearchViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        if #available(iOS 15.0, *) {
            List(viewModel.results) { result in
                NavigationLink(destination: SearchResultView(searchResultObject: result.object)) {
                    Text(result.title)
                }
            }
            .searchable(text: $searchText, placement:
                    .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { newValue in
                viewModel.setSearchText(newValue)
            }
            .navigationTitle("Search in the App")
            .listStyle(PlainListStyle())
        } else {
            // Fallback on earlier versions
        }
    }
}
