//
//  ContentView.swift
//  on-track
//
//  Created by Alexey Ankip on 12.08.22.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    var body: some View {
        Button("Reload", action: WidgetCenter.shared.reloadAllTimelines)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
