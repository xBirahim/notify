import ArgumentParser

enum NotifyCategory: String, Codable, ExpressibleByArgument {
    case plain = "PLAIN"
    case alert = "ALERT"
    case job = "JOB"
    case deploy = "DEPLOY"
}

enum NotifyAction: String {
    case acknowledge = "ACK"
    case open = "OPEN"
    case retry = "RETRY"
    case silence = "SILENCE"
    case rollback = "ROLLBACK"
}
