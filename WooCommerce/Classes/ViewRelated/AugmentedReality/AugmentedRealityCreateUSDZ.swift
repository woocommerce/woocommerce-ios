import SwiftUI

@available(macCatalyst 16.0, *)
struct AugmentedRealityCreateUSDZ: View {
    @ObservedObject var viewModel: AugmentedRealityCreateUSDZViewModel

    init(viewModel: AugmentedRealityCreateUSDZViewModel = AugmentedRealityCreateUSDZViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Button(action: viewModel.importFilesTapped) { Text("Select images") }
            Button(action: viewModel.goTapped) { Text("Go") }
                .disabled(viewModel.selectedFolderURL == nil)
        }
        .fileImporter(isPresented: $viewModel.showDocumentPicker,
                      allowedContentTypes: [.folder],
                      allowsMultipleSelection: false,
                      onCompletion: viewModel.foldersSelected(_:))
    }
}

import RealityKit

@available(macCatalyst 16.0, *)
class AugmentedRealityCreateUSDZViewModel: ObservableObject {
    @Published var showDocumentPicker: Bool = false
    @Published var selectedFolderURL: URL? = nil

    func importFilesTapped() {
        selectedFolderURL = nil
        showDocumentPicker = true
    }

    func foldersSelected(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard urls.count == 1 else {
                return DDLogError("🥽 More than one folder of images selected")
            }
            selectedFolderURL = urls.first
        case .failure(let error):
            DDLogError("🥽 Could not fetch folder: \(error.localizedDescription)")
        }
    }

    func goTapped() {
        createUSDZ()
    }

    func createUSDZ() {
    }
}
