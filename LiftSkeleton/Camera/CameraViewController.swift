//
//  CameraViewController.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//
//

import UIKit
import AVFoundation
import Vision

final class CameraViewController: UIViewController {

    private let cameraManager = CameraManager()
    private let poseDetector = PoseDetector()

    private let previewView = CameraPreviewView()
    private let overlayView = PoseOverlayView()

    private var isProcessingFrame = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        previewView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(previewView)
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        previewView.previewLayer.videoGravity = .resizeAspectFill
        previewView.previewLayer.session = cameraManager.session
        overlayView.previewLayer = previewView.previewLayer

        cameraManager.onFrame = { [weak self] sampleBuffer in
            self?.handle(sampleBuffer: sampleBuffer)
        }

        requestCameraAccessAndStart()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overlayView.frame = view.bounds
    }

    private func requestCameraAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureAndStart()
                    }
                }
            }
        default:
            break
        }
    }

    private func configureAndStart() {
        cameraManager.configureSession { [weak self] success in
            guard success else { return }
            self?.cameraManager.startRunning()
        }
    }

    private func handle(sampleBuffer: CMSampleBuffer) {
        guard !isProcessingFrame else { return }
        isProcessingFrame = true

        let observation = poseDetector.detectPose(in: sampleBuffer, orientation: .left)

        DispatchQueue.main.async { [weak self] in
            self?.overlayView.observation = observation
            self?.isProcessingFrame = false
        }
    }
}
