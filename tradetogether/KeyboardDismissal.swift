//
//  KeyboardDismissal.swift
//  tradetogether
//
//  Created by Codex on 10/05/26.
//

import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnBackgroundTap() -> some View {
        onTapGesture {
            UIApplication.shared.dismissKeyboard()
        }
    }

    func interactiveKeyboardDismissal() -> some View {
        scrollDismissesKeyboard(.interactively)
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
