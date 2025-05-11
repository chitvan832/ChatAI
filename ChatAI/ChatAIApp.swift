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
//        self.apiKey = "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"
//        //Poo Account
//        self.apiKey = "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"
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
