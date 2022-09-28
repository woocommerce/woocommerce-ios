import Foundation
import SwiftUI

struct SearchView: View {
    let names: [String] = []
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            if #available(iOS 15.0, *) {
                List {
                    ForEach(searchResults, id: \.self) { name in
                        NavigationLink(destination: Text(name)) {
                            Text(name)
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
                    ForEach(searchResults, id: \.self) { result in
                        Text("Are you looking for \(result)?").searchCompletion(result)
                    }
                }
                .navigationTitle("Search in the App")
                .listStyle(PlainListStyle())
            } else {
                // Fallback on earlier versions
            }
        }
    }

    var searchResults: [String] {
        if searchText.isEmpty {
            return names
        } else {
            return names.filter { $0.contains(searchText) }
        }
    }
}
