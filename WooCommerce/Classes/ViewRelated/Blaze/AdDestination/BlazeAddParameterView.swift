import SwiftUI

final class BlazeAddParameterViewModel: ObservableObject {
    @Published var key: String = ""
    @Published var value: String = ""

    let remainingCharacters: Int

    typealias BlazeAddParameterCompletionHandler = (_ key: String, _ value: String) -> Void
    private let completionHandler: BlazeAddParameterCompletionHandler

    init(remainingCharacters: Int,
         onCompletion: @escaping BlazeAddParameterCompletionHandler) {
        self.remainingCharacters = remainingCharacters
        self.completionHandler = onCompletion
    }

    // todo: use this in view
    func onSave() {
        completionHandler(key, value)
    }
}


/// View for adding a parameter to a Blaze campaign's URL.
///
struct BlazeAddParameterView: View {
    @ObservedObject private var viewModel: BlazeAddParameterViewModel


    init(viewModel: BlazeAddParameterViewModel) {
        self.viewModel = viewModel
    }


    var body: some View {
        Text("Hello, World!")
    }
}

struct BlazeAddParameterView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeAddParameterView(viewModel: BlazeAddParameterViewModel(remainingCharacters: 999) { _, _ in })
    }
}
