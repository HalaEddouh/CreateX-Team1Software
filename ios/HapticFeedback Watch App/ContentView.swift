//
//  ContentView.swift
//  HapticFeedback Watch App
//
//  Created by Neeti Jain on 4/22/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(viewModel.latestCommand)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
