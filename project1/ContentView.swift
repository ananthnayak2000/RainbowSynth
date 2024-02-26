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
    @State private var immersiveEffect: SurroundingsEffect? = nil
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

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
        .preferredSurroundingsEffect(immersiveEffect)
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                        immersiveEffect = .systemDark
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                    immersiveEffect = nil
                }
            }
        }
        // Fixes issue with quiting app while in immersive mode. Have not figured out how to solve deprecated issues.
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .inactive || newScenePhase == .background {
                showImmersiveSpace = false
                immersiveEffect = nil
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
