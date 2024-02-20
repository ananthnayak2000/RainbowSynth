//
//  ContentView.swift
//  project1
//
//  Created by Ananth Nayak on 2/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            Text(immersiveSpaceIsShown ? "Enjoy your journey." : "Hello, Wanderer.")
                .animation(.easeInOut(duration: 0.06))
                .padding(.bottom, 12)
                .multilineTextAlignment(.center)
            Text(immersiveSpaceIsShown ? "Go for rainbow synthesizers. Happy music listening." : "Welcome to the immersive world of spatial music.")
                .animation(.easeInOut(duration: 0.06))
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            Toggle(immersiveSpaceIsShown ? "Exit Immersive View" : "Start Experience", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 32)
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
