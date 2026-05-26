import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationListView()
                .tag(0)
                .tabItem {
                    Label("Chats", systemImage: selectedTab == 0
                          ? "bubble.left.and.bubble.right.fill"
                          : "bubble.left.and.bubble.right")
                }

            BookmarksView()
                .tag(1)
                .tabItem {
                    Label("Bookmarks", systemImage: selectedTab == 1
                          ? "bookmark.fill"
                          : "bookmark")
                }

            SettingsView()
                .tag(2)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 2
                          ? "gearshape.fill"
                          : "gearshape")
                }
        }
        .tint(AppColors.accent)
    }
}
