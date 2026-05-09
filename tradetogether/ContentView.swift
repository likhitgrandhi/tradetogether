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
    @StateObject private var settings = SeekAPISettings.shared
    @State private var showSplash = true

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        appearance.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 0.92)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(red: 0.702, green: 0.702, blue: 0.702, alpha: 1)
        itemAppearance.selected.iconColor = UIColor.white
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        Group {
            if showSplash {
                GrowHouseSplashView()
            } else if !settings.isAuthenticated || !settings.onboardingCompleted {
                OnboardingView()
            } else {
                mainTabs
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            withAnimation(.easeInOut(duration: 0.28)) {
                showSplash = false
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                FeedView(store: store)
            }
            .tabItem {
                Image(systemName: "house.fill")
            }

            NavigationStack {
                TradesHubView(store: store)
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
        .toolbarColorScheme(.dark, for: .tabBar)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
