//
//  CameraContainerView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import SwiftUI

struct CameraContainerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
