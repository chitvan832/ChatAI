//
//  ChatAIApp.swift
//  ChatAI
//
//  Created by CS on 10/05/25.
//

import SwiftUI
import SwiftData

@main
struct ChatAIApp: App {
    
    private let apiKey: String
    
    init() {
        self.apiKey = Config.cohereAPIKey
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
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
