import SwiftUI
import SwiftData

@main
struct LogicaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Slate.self)
    }
}
