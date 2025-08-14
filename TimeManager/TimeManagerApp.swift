//
//  TimeManagerApp.swift
//  TimeManager
//
//  Created by João Felipe Schwaab on 12/08/25.
//

import SwiftUI
import SwiftData

@main
struct TimeManagerApp: App {
    

    var body: some Scene {
        WindowGroup {
            ContentView()

        }.modelContainer(for: Task.self)

    }
}
