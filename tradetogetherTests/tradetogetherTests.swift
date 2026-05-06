//
//  tradetogetherTests.swift
//  tradetogetherTests
//
//  Created by Likhit Grandhi on 05/05/26.
//

import Testing
@testable import tradetogether

@MainActor
struct tradetogetherTests {

    @Test func profileStatsUseClosedIdeasOnly() async throws {
        let store = DemoStore.shared
        let maya = store.profile(id: "maya")
        let stats = TradeMetrics.stats(for: maya, posts: store.posts(for: maya))

        #expect(stats.closedIdeas == 1)
        #expect(stats.wins == 1)
        #expect(stats.winRate == 100)
        #expect(stats.activeIdeas == 1)
    }

    @Test func stockFilteringReturnsOnlyRelatedPosts() async throws {
        let store = DemoStore.shared
        let reliance = store.stock(id: "reliance")
        let related = store.posts(for: reliance)

        #expect(related.count == 1)
        #expect(related.allSatisfy { $0.stockID == reliance.id })
    }

    @Test func supportsUSAndIndiaSymbols() async throws {
        let store = DemoStore.shared
        let regions = Set(store.stocks.map(\.region))

        #expect(regions.contains(.us))
        #expect(regions.contains(.india))
        #expect(store.stock(id: "aapl").displaySymbol == "AAPL - NASDAQ")
        #expect(store.stock(id: "reliance").displaySymbol == "RELIANCE - NSE")
    }
}
