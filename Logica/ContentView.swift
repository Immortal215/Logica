import SwiftUI
import SwiftData
import Foundation
import FoundationModels

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var slates: [Slate]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(slates) { i in
                    Text(i.text)
                }
            }
            .navigationTitle("Found Slates")
        }
        .onAppear {
            if (slates.isEmpty) {
                addItem(Discovery(text: "Fire", emoji: "🔥", creators: [""]), at: CGPoint())
                addItem(Discovery(text: "Water", emoji: "💧", creators: [""]), at: CGPoint())
                addItem(Discovery(text: "Earth", emoji: "🌍", creators: [""]), at: CGPoint())
                addItem(Discovery(text: "Wind", emoji: "💨", creators: [""]), at: CGPoint())
            }
        }
    }
    func addItem(_ discovery: Discovery, at location: CGPoint) {
        withAnimation {
            let newItem = Slate(discovery: discovery, placedLocation: location)
            modelContext.insert(newItem)
        }
    }

    func deleteItem(_ item: Slate) {
        withAnimation {
            modelContext.delete(item)
        }
    }

    func moveItem(_ item: Slate, to location: CGPoint) {
        withAnimation {
            item.location = location
        }
    }
}



final class CraftCombiner {
    let session = LanguageModelSession()
    
    func combine(a: String, b: String, discovered: [String]) async throws -> String {
        let cap = 1000
        let known = discovered.prefix(cap).joined(separator: ", ")
        
        let prompt = """
        You are an Infinite Craft word-combination engine.
        
        Combine A and B into exactly one new item.
        
        A: \(a)
        B: \(b)
        
        Already discovered items (reuse an exact match if it is the best answer):
        \(known)
        
        Rules:
        - Output should be only two strings seperated by a comma.
        - There are two outputs: Name and Emoji.
        - Output should look like this "Name, Emoji" 
        - name must be 1 to 3 words, Title Case, no punctuation.
        - Prefer something conceptually related to A and B.
        - The emoji must be an Apple emoji most related to the word
        """
        
        do {
            return try await session.respond(to: prompt).content
        } catch {
            return ""
        }
    }
}
