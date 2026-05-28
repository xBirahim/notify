import ArgumentParser

enum NotifyCategory: String, Codable, ExpressibleByArgument {
    case plain = "plain"
    case alert = "alert"
    case job = "job"
    case deploy = "deploy"
}

enum NotifyAction: String {
    case acknowledge = "ACK"
    case open = "OPEN"
    case retry = "RETRY"
    case silence = "SILENCE"
    case rollback = "ROLLBACK"
}
