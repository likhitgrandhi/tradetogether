//
//  tradetogetherApp.swift
//  tradetogether
//
//  Created by Likhit Grandhi on 05/05/26.
//

import SwiftUI
import CoreText

@main
struct tradetogetherApp: App {
    init() {
        SeekFontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

enum SeekFontRegistrar {
    static func registerFonts() {
        ["Inter", "Inter-Italic"].forEach { fileName in
            let url = Bundle.main.url(forResource: fileName, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: fileName, withExtension: "ttf")
            guard let url else {
                return
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
