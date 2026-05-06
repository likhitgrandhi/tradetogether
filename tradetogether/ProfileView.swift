//
//  ProfileView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct ProfileView: View {
    let profile: TraderProfile
    let posts: [TradeIdea]
    let store: DemoStore

    var body: some View {
        let stats = TradeMetrics.stats(for: profile, posts: posts)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                WSJMasthead()
                profileHeader(stats: stats)
                postHistory
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func profileHeader(stats: ProfileStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: profile, size: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text("\(profile.handle) - \(profile.role)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TradeTheme.muted)
                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(TradeTheme.ink.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                MetricPill(title: "Win Rate", value: "\(stats.winRate)%", tint: TradeTheme.gain)
                MetricPill(title: "Closed", value: "\(stats.closedIdeas)")
                MetricPill(title: "Avg Return", value: stats.averageReturn.percentText, tint: stats.averageReturn >= 0 ? TradeTheme.gain : TradeTheme.loss)
            }

            HStack(spacing: 8) {
                MetricPill(title: "Active Ideas", value: "\(stats.activeIdeas)")
                MetricPill(title: "Followers", value: profile.followers)
            }
        }
        .padding(14)
        .background(TradeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var postHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Idea History", subtitle: "Closed ideas power the credibility score")
            ForEach(posts) { post in
                NavigationLink {
                    PostDetailView(post: post, store: store)
                } label: {
                    TradeIdeaCard(
                        post: post,
                        author: profile,
                        stock: store.stock(id: post.stockID),
                        stats: TradeMetrics.stats(for: profile, posts: posts)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
