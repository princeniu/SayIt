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

#if !DISABLE_PREVIEWS
#Preview {
    ContentView()
        .environmentObject(AppController())
}
#endif
