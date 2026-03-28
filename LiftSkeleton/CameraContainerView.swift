//
//  CameraContainerView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import SwiftUI

struct CameraContainerView: UIViewControllerRepresentable {
    @Binding var switchCameraTrigger: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
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
    }

    final class Coordinator {
        weak var controller: CameraViewController?
    }
}
//import SwiftUI
//
//struct CameraContainerView: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> CameraViewController {
//        CameraViewController()
//    }
//
//    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
//}
