//
//  project1App.swift
//  project1
//
//  Created by Ananth Nayak on 2/8/24.
//

import SwiftUI

@main
struct project1App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 350, idealWidth: 380, maxWidth: 380,
                    minHeight: 350, idealHeight: 380, maxHeight: 380)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
