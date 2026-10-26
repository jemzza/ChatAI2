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
    let photoAccess: any PhotoLibraryAccess
    let photoSaver: any PhotoSaving
    let thumbnails: any VideoThumbnailing
    let settings: any SettingsStorable
    let notifications: any LocalNotificationScheduling
    let cache: any CacheManaging
}
