//
//  ContentView.swift
//  SayIt
//
//  Created by 牛拙 on 2/2/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        PopoverView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppController())
}
