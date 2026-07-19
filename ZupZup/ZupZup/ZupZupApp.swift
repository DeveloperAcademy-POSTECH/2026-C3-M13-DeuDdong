//
//  ZupZupApp.swift -> 앱 진입점
//  ZupZup
//
//  Created by 승민 on 5/29/26.
//

import SwiftUI
import FirebaseCore

@main
struct ZupZupApp: App {
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
