//
//  ChatAIApp.swift
//  ChatAI
//
//  Created by CS on 10/05/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct ChatAIApp: App {
    
    private let apiKey: String
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        self.apiKey = Config.cohereAPIKey
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ChatView(apiKey: apiKey)
        }
        .modelContainer(sharedModelContainer)
    }
}
