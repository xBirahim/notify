struct NotificationPayload: Codable {
    var id: String?
    var title: String?
    var subtitle: String?
    var message: String
    var level: NotificationLevel
    var group: String?
    var sound: NotificationSound
    var thread: String?
    var category: String?
    var url: String?
    var userInfo: [String: String]
}
