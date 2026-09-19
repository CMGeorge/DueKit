import Foundation

public extension Date {
    var year: Int { Calendar.dueKitCalendar(for: self).component(.year, from: self) }
    var month: Int { Calendar.dueKitCalendar(for: self).component(.month, from: self) }
    var day: Int { Calendar.dueKitCalendar(for: self).component(.day, from: self) }
    var hour: Int { Calendar.dueKitCalendar(for: self).component(.hour, from: self) }
    var minute: Int { Calendar.dueKitCalendar(for: self).component(.minute, from: self) }
}

private extension Calendar {
    static func dueKitCalendar(for date: Date) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        // Preserve the current time zone at the moment of evaluation
        cal.timeZone = TimeZone.current
        return cal
    }
}
