//
//  ContentView.swift
//  tradetogether
//
//  Created by Likhit Grandhi on 05/05/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    private let store = DemoStore.shared

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialLight)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.96)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(white: 0.47, alpha: 1)
        itemAppearance.selected.iconColor = UIColor.black
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            NavigationStack {
                FeedView(store: store)
            }
            .tabItem {
                Image(systemName: "house.fill")
            }

            NavigationStack {
                WatchlistView(store: store)
            }
            .tabItem {
                Image(systemName: "arrow.2.squarepath")
            }

            NavigationStack {
                TradeComposerView(author: store.currentUser, stocks: store.stocks)
            }
            .tabItem {
                Image(systemName: "plus.square")
            }

            NavigationStack {
                DiscoverView(store: store)
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }

            NavigationStack {
                ProfileView(profile: store.currentUser, posts: store.posts(for: store.currentUser), store: store)
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
            }
        }
        .tint(TradeTheme.ink)
        .toolbarBackground(TradeTheme.paper, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
