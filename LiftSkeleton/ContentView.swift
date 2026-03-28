//
//  ContentView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var switchCameraTrigger = false
    @State private var recordTrigger = false
    @State private var isRecording = false

    var body: some View {
        ZStack {
            CameraContainerView(
                switchCameraTrigger: $switchCameraTrigger,
                recordTrigger: $recordTrigger,
                isRecording: $isRecording
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()

                    Button {
                        switchCameraTrigger = true
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 22, weight: .semibold))
                            .padding()
                            .background(.black.opacity(0.6))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    .padding(.top, 24)
                    .padding(.trailing, 20)
                }

                Spacer()

                Button {
                    recordTrigger = true
                } label: {
                    Circle()
                        .fill(isRecording ? Color.red : Color.white)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.25), lineWidth: 4)
                        )
                        .padding(.bottom, 32)
                }
            }
        }
    }
}
