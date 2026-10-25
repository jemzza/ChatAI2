import PhotosUI
import SwiftUI

struct TemplatePreviewView: View {
    private enum Dropdown {
        case format
        case quality
    }
    
    @StateObject private var model: TemplatePreviewViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var dropdown: Dropdown?
    @State private var isPickerPresented = false
    @State private var pickerItem: PhotosPickerItem?
    private let thumbnails: any VideoThumbnailing
    private let photoAccess: any PhotoLibraryAccess
    
    init(templateId: Int64, category: String?, dependencies: AppDependencies) {
        thumbnails = dependencies.thumbnails
        photoAccess = dependencies.photoAccess
        let video = dependencies.video
        _model = StateObject(wrappedValue: TemplatePreviewViewModel(
            templateId: templateId,
            category: category,
            api: dependencies.videoAPI,
            subscription: dependencies.subscription
        ) { template, photo, aspect, quality in
            try await video.create(template: template, photo: photo, aspect: aspect, quality: quality)
        })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: model.currentTemplate.map { Text($0.name) }) {
                router.pop()
            }
            .animation(.none, value: model.currentIndex)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TemplateCarousel(templates: model.templates, index: $model.currentIndex, thumbnails: thumbnails)
                        .frame(height: 311)
                        .padding(.horizontal, -AppMetrics.sideInset)
                    PhotoSlot(state: model.photo, onAdd: addPhoto, onRemove: model.removePhoto)
                    VStack(spacing: 8) {
                        OptionRow(title: "Format", value: Text(model.aspect.rawValue)) { toggle(.format) }
                            .anchorPreference(key: DropdownAnchorKey.self, value: .bounds) {
                                dropdown == .format ? $0 : nil
                            }
                        OptionRow(title: "Quality", value: Text(model.quality.title)) { toggle(.quality) }
                            .anchorPreference(key: DropdownAnchorKey.self, value: .bounds) {
                                dropdown == .quality ? $0 : nil
                            }
                    }
                }
                .padding(.horizontal, AppMetrics.sideInset)
                .padding(.vertical, 16)
            }
            .scrollBounceBehaviorIfAvailable()
            GradientButton(title: "Create", isEnabled: model.canCreate, isLoading: model.isCreating) {
                Haptics.play(.tap)
                Task { await model.create() }
            }
            .padding(.horizontal, AppMetrics.sideInset)
            .padding(.bottom, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .overlayPreferenceValue(DropdownAnchorKey.self) { anchor in
            GeometryReader { proxy in
                if let anchor, let dropdown {
                    let row = proxy[anchor]
                    ZStack(alignment: .topLeading) {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { self.dropdown = nil } }
                        menu(for: dropdown)
                            .frame(width: row.maxX, height: row.maxY, alignment: .bottomTrailing)
                    }
                }
            }
        }
        .toast($model.toast)
        .haptic(on: model.toast, ToastMessage.haptic(for:))
        .photosPicker(isPresented: $isPickerPresented, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            pickerItem = nil
            Task { await model.loadPhoto { try await item.loadTransferable(type: Data.self) } }
        }
        .task { await model.load() }
        .onAppear {
            model.onPaywall = { [router] in router.showPaywall(from: .premiumAction) }
            model.onCreated = { [router] id in router.replaceTop(with: .generation(id: id)) }
        }
    }
    
    private func addPhoto() {
        Task {
            if await photoAccess.requestAccess() { isPickerPresented = true }
        }
    }
    
    private func toggle(_ menu: Dropdown) {
        withAnimation(.easeOut(duration: 0.2)) { dropdown = dropdown == menu ? nil : menu }
    }
    
    private func close() {
        withAnimation(.easeOut(duration: 0.2)) { dropdown = nil }
    }
    
    @ViewBuilder
    private func menu(for dropdown: Dropdown) -> some View {
        switch dropdown {
            case .format:
                DropdownMenu(options: VideoAspect.allCases, selection: model.aspect) { aspect in
                    HStack(spacing: 12) {
                        AspectIcon(aspect: aspect, isSelected: aspect == model.aspect)
                        DropdownOptionText(title: Text(aspect.rawValue), subtitle: aspect.subtitle, isSelected: aspect == model.aspect)
                    }
                } onSelect: { aspect in
                    model.aspect = aspect
                    close()
                }
            case .quality:
                DropdownMenu(options: TemplatePreviewViewModel.QualityOption.allCases, selection: model.quality) { option in
                    DropdownOptionText(title: Text(option.title), subtitle: option.subtitle, isSelected: option == model.quality)
                } onSelect: { option in
                    model.quality = option
                    close()
                }
        }
    }
}
