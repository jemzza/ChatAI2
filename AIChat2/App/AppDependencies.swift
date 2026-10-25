import Foundation

@MainActor
struct AppDependencies {
    let subscription: any SubscribableService
    let chats: any ChatRepository
    let chat: ChatService
    let videos: any VideoRepository
    let videoAPI: any VideoAPI
    let media: any MediaStoring
    let video: VideoGenerationService
    let thumbnails: any VideoThumbnailing
}
