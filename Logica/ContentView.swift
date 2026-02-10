import SwiftUI

struct ContentView: View {
    @StateObject var store = MathWikiStore()

    var body: some View {
        NavigationStack(path: $store.navigationPath) {
            Group {
                if store.isLoading {
                    ProgressView("Loading Logica...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = store.loadErrorMessage {
                    VStack(spacing: 10) {
                        Text("Could not load bundled content")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            store.load()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HomeView(store: store, openPage: openPage)
                }
            }
            .navigationDestination(for: String.self) { pageID in
                if let page = store.page(id: pageID) {
                    PageView(page: page, store: store, openPage: openPage)
                } else {
                    ContentUnavailableView("Page Missing", systemImage: "questionmark.square")
                }
            }
            .navigationTitle("Logica")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        store.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!store.canGoBack)

                    Button {
                        store.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!store.canGoForward)
                }
            }
        }
        .onChange(of: store.navigationPath) { _, newPath in
            store.registerNavigationChangeIfNeeded(newPath)
        }
    }

    func openPage(_ pageID: String) {
        store.openPage(pageID)
    }
}
