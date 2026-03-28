//
//  CameraContainerView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import SwiftUI

struct CameraContainerView: UIViewControllerRepresentable {
    @Binding var switchCameraTrigger: Bool
    @Binding var recordTrigger: Bool
    @Binding var isRecording: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()

        controller.onRecordingStateChanged = { recording in
            DispatchQueue.main.async {
                self.isRecording = recording
            }
        }

        context.coordinator.controller = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if switchCameraTrigger {
            context.coordinator.controller?.switchCamera()

            DispatchQueue.main.async {
                self.switchCameraTrigger = false
            }
        }

        if recordTrigger {
            context.coordinator.controller?.toggleRecording()

            DispatchQueue.main.async {
                self.recordTrigger = false
            }
        }
    }

    final class Coordinator {
        weak var controller: CameraViewController?
    }
}
