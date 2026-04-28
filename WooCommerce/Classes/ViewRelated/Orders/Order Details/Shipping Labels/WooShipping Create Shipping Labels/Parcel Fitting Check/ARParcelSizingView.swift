import SwiftUI

/// Custom-flow AR view: drop a translucent cuboid, resize it via three
/// sliders, drag and rotate to align with the real parcel, and feed the
/// resulting L / W / H back to the Add Package form.
///
/// Dimensions are tracked internally in inches to match the form's display
/// units; conversion to metres happens at the boundary with `ARCuboidView`
/// (RealityKit always works in metres).
struct ARParcelSizingView: View {
    private let onCancel: () -> Void
    private let onConfirm: (_ length: Double, _ width: Double, _ height: Double) -> Void

    @State private var lengthInches: Float
    @State private var widthInches: Float
    @State private var heightInches: Float

    @State private var hasValidTarget: Bool = false
    @State private var isPlaced: Bool = false
    @State private var placeTrigger: Int = 0
    @State private var resetTrigger: Int = 0

    init(initialLengthInches: Double = 8.0,
         initialWidthInches: Double = 6.0,
         initialHeightInches: Double = 4.0,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (_ length: Double, _ width: Double, _ height: Double) -> Void) {
        self._lengthInches = State(initialValue: Float(initialLengthInches))
        self._widthInches = State(initialValue: Float(initialWidthInches))
        self._heightInches = State(initialValue: Float(initialHeightInches))
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            ARCuboidView(
                dimensions: dimensionsInMeters,
                hasValidTarget: $hasValidTarget,
                isPlaced: $isPlaced,
                placeTrigger: placeTrigger,
                resetTrigger: resetTrigger
            )
            .ignoresSafeArea()

            if !isPlaced {
                ARCuboidReticle(active: hasValidTarget)
                    .allowsHitTesting(false)
            }

            VStack {
                topToolbar

                if !isPlaced {
                    hintBanner
                }

                Spacer()

                bottomControls
            }
            .animation(.easeInOut(duration: 0.2), value: isPlaced)
        }
        .background(Color.black)
    }

    private var topToolbar: some View {
        HStack {
            ARCuboidCircleIconButton(systemName: "xmark", action: onCancel)
            Spacer()
            if isPlaced {
                ARCuboidCircleIconButton(systemName: "trash") {
                    resetTrigger += 1
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var hintBanner: some View {
        Text(isPlaced ? "" : "Aim the reticle at the parcel and tap + to place the cuboid")
            .font(.callout)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(.horizontal)
            .padding(.top, 8)
    }

    @ViewBuilder
    private var bottomControls: some View {
        if isPlaced {
            VStack(spacing: 14) {
                slider(label: "Length", value: $lengthInches)
                slider(label: "Width", value: $widthInches)
                slider(label: "Height", value: $heightInches)

                Button {
                    onConfirm(Double(lengthInches),
                              Double(widthInches),
                              Double(heightInches))
                } label: {
                    Text("Use these dimensions")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.yellow, in: Capsule())
                        .foregroundStyle(.black)
                }
            }
            .padding(16)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
            .padding()
        } else {
            ARCuboidPlaceButton(active: hasValidTarget) {
                placeTrigger += 1
            }
            .padding(.bottom, 40)
        }
    }

    private func slider(label: String, value: Binding<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f in", value.wrappedValue))
                    .font(.subheadline.monospacedDigit())
            }
            .foregroundStyle(.white)
            Slider(value: value, in: 0.5...20.0)
                .tint(.yellow)
        }
    }

    /// Inches → metres mapping for ARKit. AR uses (X = length, Y = height,
    /// Z = width) so the cuboid sits on its largest face by default.
    private var dimensionsInMeters: SIMD3<Float> {
        let inch: Float = 0.0254
        return SIMD3(lengthInches * inch,
                     heightInches * inch,
                     widthInches * inch)
    }
}
