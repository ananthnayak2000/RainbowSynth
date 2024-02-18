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
            Model3D(named: "Rainbow Synth", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text(immersiveSpaceIsShown ? "Welcome to the Immersive World of Music" : "Hello, wanderer!")
                .animation(.easeInOut(duration: 5))
            Text(immersiveSpaceIsShown ? "Enjoy your journey!" : "Are you ready to experience a world of Music")
                .animation(.easeInOut(duration: 5))
            
            Toggle(immersiveSpaceIsShown ? "Hide Rainbow Synthesizer" : "Show Rainbow Synthesizer", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 50)
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
