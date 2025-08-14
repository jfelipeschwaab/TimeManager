//
//  ContentView.swift
//  TimeManager
//
//  Created by João Felipe Schwaab on 12/08/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TaskListView(context: context)
    }
}


#Preview {
    ContentView()
}
