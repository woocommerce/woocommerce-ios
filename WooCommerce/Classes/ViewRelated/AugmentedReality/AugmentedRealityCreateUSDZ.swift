import SwiftUI
import QuickLook

@available(macCatalyst 16.0, *)
struct AugmentedRealityCreateUSDZ: View {
    @ObservedObject var viewModel: AugmentedRealityCreateUSDZViewModel

    init(viewModel: AugmentedRealityCreateUSDZViewModel = AugmentedRealityCreateUSDZViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 32.0) {
            Button(action: viewModel.importFilesTapped) { Text("Select images") }
                .buttonStyle(.borderedProminent)
            Picker("Quality", selection: $viewModel.quality) {
                ForEach(QualityOptions.allCases) { level in
                    Text(level.name)
                }
            }
            Button(action: viewModel.goTapped) { Text("Go") }
                .disabled(viewModel.selectedFolderURL == nil)
                .buttonStyle(.borderedProminent)
            ProgressView("Generating: ", value: viewModel.progress)
            Button(action: viewModel.showPreviewTapped) { Text("Preview 3D model") }
                .disabled(viewModel.generatedFileURL == nil)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .fileImporter(isPresented: $viewModel.showDocumentPicker,
                      allowedContentTypes: [.folder],
                      allowsMultipleSelection: false,
                      onCompletion: viewModel.foldersSelected(_:))
        .sheet(isPresented: $viewModel.previewShowing) {
            if let url = viewModel.generatedFileURL {
                PreviewController(url: url)
            } else {
                EmptyView()
            }
        }
    }
}

struct PreviewController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> WooNavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        let navigationController = WooNavigationController(rootViewController: controller)
        navigationController.addCloseNavigationBarButton()
        return navigationController
    }

    func updateUIViewController(_ uiViewController: WooNavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
        let parent: PreviewController
        init(parent: PreviewController) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }

        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            return .updateContents
        }
    }
}

import RealityKit

enum QualityOptions: CaseIterable, Identifiable {
    case maximum
    case high
    case medium
    case reduced
    case preview

    var id: QualityOptions {
        self
    }

    var name: String {
        switch self {
        case .maximum:
            return "Maximum"
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .reduced:
            return "Reduced"
        case .preview:
            return "Preview"
        }
    }

    var photogrammetryDetail: PhotogrammetrySession.Request.Detail {
        switch self {
        case .maximum:
            return .raw
        case .high:
            return .full
        case .medium:
            return .medium
        case .reduced:
            return .reduced
        case .preview:
            return .preview
        }
    }
}

@available(macCatalyst 16.0, *)
class AugmentedRealityCreateUSDZViewModel: ObservableObject {
    @MainActor @Published var showDocumentPicker: Bool = false
    @MainActor @Published var selectedFolderURL: URL? = nil
    @MainActor @Published var generatedFileURL: URL? = nil
    @MainActor @Published var previewShowing: Bool = false
    @MainActor @Published var progress: Double = 0
    @MainActor var quality: QualityOptions = .high

    func importFilesTapped() {
        Task {
            await MainActor.run {
                selectedFolderURL = nil
                generatedFileURL = nil
                showDocumentPicker = true
            }
        }
    }

    func foldersSelected(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard urls.count == 1 else {
                return DDLogError("🥽 More than one folder of images selected")
            }
            Task {
                await MainActor.run {
                    selectedFolderURL = urls.first
                }
            }
        case .failure(let error):
            DDLogError("🥽 Could not fetch folder: \(error.localizedDescription)")
        }
    }

    func goTapped() {
        Task {
            await MainActor.run {
                generatedFileURL = nil
                progress = 0

                guard PhotogrammetrySession.isSupported else {
                    return DDLogError("🥽 Photogrammetry not supported")
                }

                createUSDZ()
            }
        }
    }

    @MainActor
    private func createUSDZ() {
        let url = URL(fileURLWithPath: "ThreeDeeModel.usdz")
        let request = PhotogrammetrySession.Request.modelFile(url: url,
                                                              detail: quality.photogrammetryDetail)
        guard let selectedFolderURL = selectedFolderURL,
            let session = try? PhotogrammetrySession(input: selectedFolderURL) else {
            return
        }

        Task {
            do {
                for try await output in session.outputs {
                    switch output {
                    case .processingComplete:
                        // RealityKit has processed all requests.
                        await MainActor.run {
                            generatedFileURL = url
                        }
                    case .requestError(let request, let error):
                        // Request encountered an error.
                        DDLogError("🥽 Request error: \(error.localizedDescription) for \(request)")
                    case .requestComplete(let request, let result):
                        // RealityKit has finished processing a request.
                        DDLogInfo("🥽 Request completed with \(result) for \(request)")
                        break
                    case .requestProgress(_, let fractionComplete):
                        // Periodic progress update. Update UI here.
                        await MainActor.run {
                            progress = fractionComplete
                        }
                    case .inputComplete:
                        // Ingestion of images is complete and processing begins.
                        DDLogInfo("🥽 Input completed for session")
                    case .invalidSample(let id, let reason):
                        // RealityKit deemed a sample invalid and didn't use it.
                        DDLogWarn("🥽 Invalid sample found: \(id) – \(reason)")
                    case .skippedSample(let id):
                        // RealityKit was unable to use a provided sample.
                        DDLogWarn("🥽 Sample skipped: \(id)")
                    case .automaticDownsampling:
                        // RealityKit downsampled the input images because of
                        // resource constraints.
                        DDLogWarn("🥽 Downsampled input due to resource constraints")
                    case .processingCancelled:
                        // Processing was canceled.
                        await MainActor.run {
                            reset()
                        }
                    @unknown default:
                        // Unrecognized output.
                        DDLogWarn("🥽 Unrecognized output")
                    }
                }
            } catch {
                DDLogError("🥽 ERROR = \(String(describing: error))")
            }
        }

        do {
            try session.process(requests: [request])
        } catch {
            print("🥽 Error processing session = \(String(describing: error))")
        }
    }

    func showPreviewTapped() {
        Task {
            await MainActor.run {
                previewShowing.toggle()
            }
        }
    }

    @MainActor
    private func reset() {
        generatedFileURL = nil
        progress = 0
        previewShowing = false

    }
}
