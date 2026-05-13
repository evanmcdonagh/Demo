import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GamesListView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt")
                }

            TeamsListView()
                .tabItem {
                    Label("Teams", systemImage: "shield.lefthalf.filled")
                }
        }
    }
}
