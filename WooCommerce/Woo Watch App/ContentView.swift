//
//  ContentView.swift
//  Woo Watch App
//
//  Created by Ernesto Carrion on 2/05/24.
//  Copyright © 2024 Automattic. All rights reserved.
//

import SwiftUI
import Networking


struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world Woo!")
        }
        .padding()
        .task {
            let credentials = Credentials(authToken: "6789")
            print("I can compile some credentials: \(credentials)")
        }
    }
}

#Preview {
    ContentView()
}
