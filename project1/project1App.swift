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
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
