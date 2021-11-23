/*
See LICENSE folder for this sample’s licensing information.

Abstract:
CameraView is the primary view displayed during image capture.
*/
import AVFoundation
import SwiftUI
import UIKit

import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "CameraPreviewView")

/// This view allows the app to display an `AVCapturePreviewLayer` in SwiftUI.
/// It's used by `CameraView`to interact with the `CameraModel`.
struct CameraPreviewView: UIViewRepresentable {
    let previewViewCornerRadius: CGFloat = 50

    class PreviewView: UIView {

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
            }
            return layer
        }

        var session: AVCaptureSession? {
            get {
                return videoPreviewLayer.session
            }
            set {
                videoPreviewLayer.session = newValue
            }
        }

        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
    }

    let session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session

        // Set the view's initial state.
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.connection?.videoOrientation = .portrait

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {  }
}
