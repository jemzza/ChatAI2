//
//  AppDependencies.swift
//  AIChat2
//

import Foundation

@MainActor
struct AppDependencies {
    let subscription: any SubscribableService
    let chats: any ChatRepository
    let chat: ChatService
}
