import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    
    @Binding var selectedConversation: Conversation?
    @Binding var isShowingNewConversation: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    isShowingNewConversation = true
                    dismiss()
                }) {
                    Label("New Conversation", systemImage: "square.and.pencil")
                }
                
                ForEach(conversations) { conversation in
                    Button(action: {
                        selectedConversation = conversation
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.title)
                                .font(.headline)
                            Text(conversation.previewText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                .onDelete(perform: deleteConversations)
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
    }
} 