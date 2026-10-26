#if DEBUG
import Foundation

enum PreviewData {
    static func seed(_ repository: any ChatRepository, now: Date = Date()) async throws {
        let travel = Folder(id: UUID(), name: "Travel", createdAt: now.addingTimeInterval(-86_400 * 10))
        let work = Folder(id: UUID(), name: "Work", createdAt: now.addingTimeInterval(-86_400 * 9))
        try await repository.createFolder(travel)
        try await repository.createFolder(work)
        
        let samples: [(title: String, question: String, answer: String, age: TimeInterval, folder: UUID?, pinned: Bool)] = [
            ("Welcome email", "Help me write a welcome email", FakeChatProvider.sampleReply, 600, nil, true),
            ("Trip ideas", "Trains between Lisbon and Porto", "Trains run every hour, the trip takes about 3 hours.", 3_600 * 5, travel.id, false),
            ("Swift concurrency basics", "Explain actors simply", "The compiler checks isolation for you, so data races are caught early.", 86_400 * 2, work.id, false),
            ("Recipe for pancakes", "Quick pancake recipe?", "Mix flour, milk and eggs, then fry on a hot pan.", 86_400 * 9, nil, false),
            ("Weekend plan", "Plan my weekend", "**Saturday:** a walk and a museum.\n**Sunday:** rest.", 86_400, nil, false)
        ]
        for sample in samples {
            let date = now.addingTimeInterval(-sample.age)
            let chat = Chat(title: sample.title, createdAt: date, folderId: sample.folder)
            let question = Message(chatId: chat.id, role: .user, text: sample.question, status: .sent, createdAt: date)
            try await repository.insertChat(chat, firstMessage: question)
            let answer = Message(
                chatId: chat.id,
                role: .assistant,
                text: sample.answer,
                status: .done,
                createdAt: date.addingTimeInterval(1)
            )
            try await repository.insertMessage(answer)
            if sample.pinned { try await repository.setPinned(chatId: chat.id, at: date) }
        }
    }
}
#endif
