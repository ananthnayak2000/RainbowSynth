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
                    minWidth: 350, idealWidth: 360, maxWidth: 360,
                    minHeight: 350, idealHeight: 360, maxHeight: 360)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
