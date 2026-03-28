//
//  CameraPreviewView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import UIKit
import AVFoundation

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}
