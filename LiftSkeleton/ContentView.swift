//
//  ContentView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//
import SwiftUI

struct ContentView: View {
    @State private var switchCameraTrigger = false

    var body: some View {
        ZStack {
            CameraContainerView(switchCameraTrigger: $switchCameraTrigger)
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
            }
        }
    }
}
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        CameraContainerView()
//            .ignoresSafeArea()
//    }
//}
//
