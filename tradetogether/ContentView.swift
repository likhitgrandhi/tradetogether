//
//  ContentView.swift
//  tradetogether
//
//  Created by Likhit Grandhi on 05/05/26.
//

import SwiftUI

struct ContentView: View {
    private let store = DemoStore.shared

    var body: some View {
        TabView {
            NavigationStack {
                FeedView(store: store)
            }
            .tabItem {
                Label("Feed", systemImage: "newspaper")
            }

            NavigationStack {
                WatchlistView(store: store)
            }
            .tabItem {
                Label("Watchlist", systemImage: "list.star")
            }

            NavigationStack {
                DiscoverView(store: store)
            }
            .tabItem {
                Label("Discover", systemImage: "magnifyingglass")
            }

            NavigationStack {
                ProfileView(profile: store.currentUser, posts: store.posts(for: store.currentUser), store: store)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        .tint(TradeTheme.ink)
        .toolbarBackground(TradeTheme.paper, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
    }
}

#Preview {
    ContentView()
}
