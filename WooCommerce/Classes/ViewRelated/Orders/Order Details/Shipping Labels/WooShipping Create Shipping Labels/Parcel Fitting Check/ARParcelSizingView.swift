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

    @Environment(\.shippingDimensionsUnit) private var dimensionsUnit

    @State private var length: Float
    @State private var width: Float
    @State private var height: Float

    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(initialLength: Double? = nil,
         initialWidth: Double? = nil,
         initialHeight: Double? = nil,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (_ length: Double, _ width: Double, _ height: Double) -> Void) {
        // Defaults are resolved later via the environment unit; pass nil
        // to use DimensionUnitConversion.defaultDimensions(for:).
        self._length = State(initialValue: initialLength.map(Float.init) ?? -1)
        self._width = State(initialValue: initialWidth.map(Float.init) ?? -1)
        self._height = State(initialValue: initialHeight.map(Float.init) ?? -1)
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            ARParcelSceneView(
                dimensions: dimensionsInMeters(length: length, width: width, height: height),
                isPlaced: $isPlaced,
                resetTrigger: resetTrigger
            )
            .ignoresSafeArea()

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
        .onAppear {
            let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
            if length < 0 { length = defaults.length }
            if width < 0 { width = defaults.width }
            if height < 0 { height = defaults.height }
        }
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
        Text("Tap on the surface to place the fitting box")
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
                slider(label: "Length", value: $length)
                slider(label: "Width", value: $width)
                slider(label: "Height", value: $height)

                Button {
                    onConfirm(Double(length),
                              Double(width),
                              Double(height))
                } label: {
                    Text("Use these dimensions")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.black)
                }
            }
            .padding(16)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private func slider(label: String, value: Binding<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f %@", value.wrappedValue, unit))
                    .font(.subheadline.monospacedDigit())
            }
            .foregroundStyle(.white)
            Slider(value: value, in: DimensionUnitConversion.sliderRange(for: unit))
                .tint(.blue)
        }
    }

    /// The active unit string — falls back to "in" if the environment is
    /// empty (e.g. when launched from the debug panel outside the shipping
    /// label flow).
    private var unit: String {
        dimensionsUnit.isEmpty ? "in" : dimensionsUnit
    }

    /// Resolves slider defaults when the init received nil (no pre-existing
    /// form values). Called on first body evaluation when the environment
    /// unit is available.
    private var resolvedLength: Float {
        length >= 0 ? length : DimensionUnitConversion.defaultDimensions(for: unit).length
    }
    private var resolvedWidth: Float {
        width >= 0 ? width : DimensionUnitConversion.defaultDimensions(for: unit).width
    }
    private var resolvedHeight: Float {
        height >= 0 ? height : DimensionUnitConversion.defaultDimensions(for: unit).height
    }

    /// Convert from the store's unit to metres for ARKit.
    private func dimensionsInMeters(length: Float, width: Float, height: Float) -> SIMD3<Float> {
        let factor = DimensionUnitConversion.metersPerUnit(unit)
        let l = (length >= 0 ? length : resolvedLength) * factor
        let h = (height >= 0 ? height : resolvedHeight) * factor
        let w = (width >= 0 ? width : resolvedWidth) * factor
        return SIMD3(l, h, w)
    }
}
