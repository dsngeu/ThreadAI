//
//  ThreadAIApp.swift
//  ThreadAI
//
//  Created by DeepakSingh on 26/05/26.
//

import SwiftUI

@main
struct ThreadAIApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dependencies)
        }
    }
}
