//
//  Page.swift
//  AIChat2
//

import SwiftUI

struct Page: Identifiable {
    let id: Int
    let image: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    
    static let pages = [
        Page(id: 0, image: "OnboardingChat", title: "Ask AI anything",
             subtitle: "Answers, emails, ideas and plans in seconds"),
        Page(id: 1, image: "OnboardingVideo", title: "Turn photos into videos",
             subtitle: "Pick a template — AI animates your photo"),
    ]
}
