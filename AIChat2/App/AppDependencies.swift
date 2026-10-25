import Foundation

@MainActor
struct AppDependencies {
    let subscription: any SubscribableService
    let chats: any ChatRepository
    let chat: ChatService
    let videoAPI: any VideoAPI
    let thumbnails: any VideoThumbnailing
}
