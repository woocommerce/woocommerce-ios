import SwiftUI

/// Hosting controller that wraps the `StoreCreationSuccessView`.
@available(iOS 17.0, *)
final class ProductImageBackgroundRemovalHostingController: UIHostingController<ProductImageBackgroundRemovalView> {
    init(viewModel: ProductImageBackgroundRemovalViewModel) {
        super.init(rootView: ProductImageBackgroundRemovalView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 17.0, *)
struct ProductImageBackgroundRemovalView: View {
    @ObservedObject private var viewModel: ProductImageBackgroundRemovalViewModel
    @State private var outputViewSize = CGSize.zero

    init(viewModel: ProductImageBackgroundRemovalViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                // TODO-jc: loading UI when output is nil
                OutputView(output: $viewModel.output)
                    .onAppear {
                        outputViewSize = geometry.size
                    }
                    .onTapGesture { location in
                        // Normalize the tap position.
                        viewModel.subjectPosition = CGPoint(x: location.x / outputViewSize.width,
                                                            y: location.y / outputViewSize.height)
                    }
            }
            Form {
                EffectPicker(effect: $viewModel.effect)
                BackgroundPicker(background: $viewModel.background)
                // TODO-jc: image picker / color picker
//                ImagePicker(pipeline: pipeline)
            }
                .frame(height: 200)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    Task { @MainActor in
                        // TODO-jc: loading UI
                        await viewModel.saveToProduct()
                    }
                }, label: {
                    Text("Save to product")
                })
            }
        }
    }
}

/// A preset picker for visual effects.
struct EffectPicker: View {

    @Binding var effect: Effect

    var body: some View {
        Picker("Effect", selection: $effect) {
            ForEach(Effect.allCases, id: \.self) { effect in
                Text(effect.rawValue)
                    .tag(effect)
            }
        }
    }
}

/// A preset picker for background images.
struct BackgroundPicker: View {

    @Binding var background: Background

    var body: some View {
        Picker("Background", selection: $background) {
            ForEach(Background.allCases, id: \.self) { background in
                Text(background.rawValue)
                    .tag(background)
            }
        }
    }
}

/// A view that displays the final postprocessed output.
struct OutputView: View {

    @Binding var output: UIImage

    var body: some View {
        Image(uiImage: output)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//#Preview {
//    ProductImageBackgroundRemovalView(viewModel: .init(productImage: <#T##ProductImage#>, imageLoader: <#T##ProductUIImageLoader#>))
//}
