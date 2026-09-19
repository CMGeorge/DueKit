//
//  DueStatusTests.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation
import DKDueStatus
import Testing

@Test func dueStatusCaseExist() {  //make sure no due case is deleted
    let _: [DueStatus] = [.overdue, .dueSoon, .upcoming]  //force compilation errro

}

private func gregorian(_ identifier: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: identifier)!
    return calendar
}

private let calendar = gregorian("Europe/Bucharest")

private func at(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 0,
    _ minute: Int = 0,
    in calendar: Calendar = calendar
) -> Date {
    calendar.date(
        from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
    )!
}

@Suite("Policy")
struct PolicyTests {
    @Test("Default window is 7 day")
    func defaultWindow() throws {
        #expect(try DueStatusPolicy().dueInDaysNotification == 7)
    }

    @Test(
        "Window limits",
        arguments: [
            (-1, false), (0, true), (366, true), (367, false),
        ]
    )
    func limits(days: Int, accepted: Bool) {
        if accepted {
            #expect(throws: Never.self) {
                try DueStatusPolicy(dueInDaysNotification: days)
            }
        } else {
            #expect(throws: DueStatusError.dueSoonDaysOutOfRange(days)) {
                try DueStatusPolicy(dueInDaysNotification: days)
            }
        }
    }
}

@Suite("Status by calendar day")
struct StatusTests {
    let policy = try! DueStatusPolicy(dueInDaysNotification: 7)
    let due = at(2026, 9, 18)

    @Test(
        "Boundaries around the due date and the window",
        arguments: [
            ((2026, 9, 18, 0, 0), DueStatus.dueSoon),  // due today, first minute
            ((2026, 9, 18, 23, 59), .dueSoon),  // due today, last minute: not overdue yet
            ((2026, 9, 19, 0, 0), .overdue),  // the next day
            ((2026, 9, 11, 0, 0), .dueSoon),  // 7 days ahead: last day of the window
            ((2026, 9, 10, 23, 59), .upcoming),  // 8 days ahead
        ]
    )
    func boundaries(now: (Int, Int, Int, Int, Int), expected: DueStatus) {
        let status = policy.status(
            of: due,
            now: at(now.0, now.1, now.2, now.3, now.4),
            in: calendar
        )
        #expect(status == expected)
    }

    @Test("The due date's time of day doesn't matter")
    func dueTimeIgnored() {
        let lateDue = at(2026, 9, 18, 23, 30)
        #expect(
            policy.status(of: lateDue, now: at(2026, 9, 18, 0, 5), in: calendar)
                == .dueSoon
        )
        #expect(
            policy.status(of: lateDue, now: at(2026, 9, 19, 0, 5), in: calendar)
                == .overdue
        )
    }

    @Test("A window of 0 means only today is due soon")
    func zeroWindow() throws {
        let todayOnly = try DueStatusPolicy(dueInDaysNotification: 0)
        #expect(
            todayOnly.status(of: due, now: at(2026, 9, 18, 12), in: calendar)
                == .dueSoon
        )
        #expect(
            todayOnly.status(of: due, now: at(2026, 9, 17, 12), in: calendar)
                == .upcoming
        )
    }
}

@Suite("Days until due")
struct DaysUntilTests {
    @Test(
        "Counts whole calendar days",
        arguments: [
            ((2026, 9, 18), (2026, 9, 18), 0),
            ((2026, 9, 18), (2026, 9, 25), 7),
            ((2026, 9, 18), (2026, 9, 10), -8),
            ((2026, 12, 31), (2027, 1, 1), 1),
            ((2028, 2, 28), (2028, 3, 1), 2),  // leap year
        ]
    )
    func days(now: (Int, Int, Int), due: (Int, Int, Int), expected: Int) {
        let result = DueStatusPolicy.daysUntil(
            dueDate: at(due.0, due.1, due.2),
            from: at(now.0, now.1, now.2),
            in: calendar
        )
        #expect(result == expected)
    }
}

@Suite("Clock changes")
struct ClockChangeTests {
    @Test(
        "Spring and autumn in Bucharest still count whole days",
        arguments: [
            ((2026, 3, 28), (2026, 3, 30), 2),  // clocks go forward on 29 Mar
            ((2026, 10, 24), (2026, 10, 26), 2),  // clocks go back on 25 Oct
        ]
    )
    func bucharest(now: (Int, Int, Int), due: (Int, Int, Int), expected: Int) {
        #expect(
            DueStatusPolicy.daysUntil(
                dueDate: at(due.0, due.1, due.2),
                from: at(now.0, now.1, now.2),
                in: calendar
            ) == expected
        )
    }

    @Test("A day without midnight (Chile, 6 Sep 2026) doesn't lose a day")
    func santiago() throws {
        // Santiago jumps from 24:00 to 01:00 on 6 Sep 2026, so that day is only 23 hours long.
        let santiago = gregorian("America/Santiago")
        let today = at(2026, 9, 6, 10, in: santiago)
        let policy = try DueStatusPolicy(dueInDaysNotification: 7)
        #expect(
            DueStatusPolicy.daysUntil(
                dueDate: at(2026, 9, 7, in: santiago),
                from: today,
                in: santiago
            ) == 1
        )
        #expect(
            policy.status(
                of: at(2026, 9, 13, in: santiago),
                now: today,
                in: santiago
            ) == .dueSoon
        )
        #expect(
            policy.status(
                of: at(2026, 9, 14, in: santiago),
                now: today,
                in: santiago
            ) == .upcoming
        )
    }

    @Test(
        "Status doesn't depend on the time zone",
        arguments: [
            "Europe/Bucharest", "America/Santiago", "Pacific/Auckland",
            "Australia/Lord_Howe", "UTC",
        ]
    )
    func timeZones(identifier: String) throws {
        let zoned = gregorian(identifier)
        let policy = try DueStatusPolicy(dueInDaysNotification: 7)
        let due = at(2026, 9, 18, in: zoned)
        #expect(
            policy.status(
                of: due,
                now: at(2026, 9, 18, 23, 59, in: zoned),
                in: zoned
            ) == .dueSoon
        )
        #expect(
            policy.status(
                of: due,
                now: at(2026, 9, 19, 0, 1, in: zoned),
                in: zoned
            ) == .overdue
        )
        #expect(
            policy.status(
                of: due,
                now: at(2026, 9, 10, 12, in: zoned),
                in: zoned
            ) == .upcoming
        )
    }
}
