import Combine
import SwiftUI

final class TemplatePreviewViewModel: ObservableObject {
    enum QualityOption: CaseIterable, Hashable {
        case p720
        case p1080
        case p4k
        
        var apiQuality: VideoQuality {
            switch self {
                case .p720: .p720
                case .p1080, .p4k: .p1080
            }
        }
    }
    
    enum PhotoState: Equatable {
        case empty
        case loading
        case loaded(Data)
    }
    
    typealias CreateVideo = (VideoTemplate, Data, VideoAspect, VideoQuality) async throws -> UUID
    
    @Published private(set) var templates: [VideoTemplate] = []
    @Published var currentIndex = 0
    @Published private(set) var photo = PhotoState.empty
    @Published var aspect = VideoAspect.landscape
    @Published var quality = QualityOption.p1080
    @Published private(set) var isCreating = false
    @Published var toast: ToastMessage?
    
    var onPaywall: () -> Void = {}
    var onCreated: (UUID) -> Void = { _ in }
    
    private let templateId: Int64
    private let category: String?
    private let api: any VideoAPI
    private let subscription: any SubscribableService
    private let createVideo: CreateVideo
    
    init(
        templateId: Int64,
        category: String?,
        api: any VideoAPI,
        subscription: any SubscribableService,
        createVideo: @escaping CreateVideo
    ) {
        self.templateId = templateId
        self.category = category
        self.api = api
        self.subscription = subscription
        self.createVideo = createVideo
    }
    
    var currentTemplate: VideoTemplate? {
        templates.indices.contains(currentIndex) ? templates[currentIndex] : nil
    }
    
    var canCreate: Bool {
        if case .loaded = photo { return currentTemplate != nil && !isCreating }
        return false
    }
    
    func load() async {
        guard templates.isEmpty, let all = try? await api.templates() else { return }
        let inCategory = category.map { category in all.filter { $0.category == category } } ?? all
        templates = inCategory.isEmpty ? all : inCategory
        currentIndex = templates.firstIndex { $0.id == templateId } ?? 0
    }
    
    func loadPhoto(_ load: () async throws -> Data?) async {
        photo = .loading
        do {
            guard let data = try await load(), !data.isEmpty else { throw CancellationError() }
            photo = .loaded(data)
        } catch {
            photo = .empty
            toast = ToastMessage(kind: .failure, text: "Upload failed")
        }
    }
    
    func removePhoto() {
        photo = .empty
    }
    
    func create() async {
        guard canCreate, case let .loaded(data) = photo, let template = currentTemplate else { return }
        guard subscription.isPremium else {
            onPaywall()
            return
        }
        isCreating = true
        defer { isCreating = false }
        do {
            onCreated(try await createVideo(template, data, aspect, quality.apiQuality))
        } catch {
            photo = .empty
            toast = ToastMessage(kind: .failure, text: "Upload failed")
        }
    }
}

extension VideoAspect {
    var subtitle: LocalizedStringKey {
        switch self {
            case .landscape: "Landscape"
            case .portrait: "Portrait · Stories"
            case .square: "Square"
        }
    }
}

extension TemplatePreviewViewModel.QualityOption {
    var title: String {
        switch self {
            case .p720: "720p"
            case .p1080: "1080p"
            case .p4k: "4K"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
            case .p720: "Faster generation"
            case .p1080: "Recommended"
            case .p4k: "Best quality"
        }
    }
}
