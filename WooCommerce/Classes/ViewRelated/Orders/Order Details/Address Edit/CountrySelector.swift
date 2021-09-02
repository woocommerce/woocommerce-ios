import SwiftUI

struct CountrySelector: View {
    var body: some View {
        ListSelector(command: CountrySelectorCommand(), tableStyle: .plain)
    }
}
