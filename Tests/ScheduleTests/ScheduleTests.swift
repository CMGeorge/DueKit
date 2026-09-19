//
//  ScheduleTests.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import DKSchedule
import Foundation
import Testing

private let calendar = Calendar.dueKit(
    timeZone: TimeZone(identifier: "Europe/Bucharest")!
)

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

/// Checks that `body` throws a `RecurrenceRuleError`, and that it's the expected case.
/// Compared by description, e.g. "dayOutOfRange(32)".
private func expectError(
    _ expected: RecurrenceRuleError,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ body: () throws -> Void
) {
    let error = #expect(
        throws: RecurrenceRuleError.self,
        sourceLocation: sourceLocation
    ) { try body() }
    if let error {
        #expect(error == expected, sourceLocation: sourceLocation)
    }
}

@Suite("Month-end anchoring")
struct MonthEndTests {
    @Test(
        "Jan 31 monthly keeps its anchor",
        arguments: [
            (2027, 1, (2027, 2, 28)),
            (2027, 2, (2027, 3, 31)),
            (2027, 3, (2027, 4, 30)),
            (2028, 1, (2028, 2, 29)),  // leap year
        ]
    )
    func jan31(startYear: Int, step: Int, expected: (Int, Int, Int)) throws {
        let start = day(startYear, 1, 31)
        let rule = try RecurrenceRule.monthlyAnchored(to: start, in: calendar)
        #expect(
            try rule.occurrence(step, from: start, in: calendar)
                == day(expected.0, expected.1, expected.2)
        )
    }

    @Test("Feb 29 yearly falls on Feb 28, then returns in leap years")
    func feb29() throws {
        let start = day(2028, 2, 29)
        let rule = try RecurrenceRule.yearlyAnchored(to: start, in: calendar)
        #expect(
            try rule.occurrence(1, from: start, in: calendar)
                == day(2029, 2, 28)
        )
        #expect(
            try rule.occurrence(4, from: start, in: calendar)
                == day(2032, 2, 29)
        )
    }
}

@Suite("Completion")
struct CompletionTests {
    @Test(
        "Next due date after completing",
        arguments: [
            ((2026, 6, 10), (2026, 7, 15)),  // early
            ((2026, 6, 15), (2026, 7, 15)),  // on the day
            ((2026, 8, 20), (2026, 9, 15)),  // overdue: missed periods skipped
            ((2026, 7, 15), (2026, 8, 15)),  // on a missed due day
        ]
    )
    func next(completed: (Int, Int, Int), expected: (Int, Int, Int)) throws {
        let rule = try RecurrenceRule(monthlyEvery: 1, on: 15)
        let result = try rule.nextOccurrence(
            after: day(completed.0, completed.1, completed.2),
            from: day(2026, 6, 15),
            in: calendar
        )
        #expect(result == day(expected.0, expected.1, expected.2))
    }
}

@Suite("Validation")
struct ValidationTests {
    @Test(
        "Invalid monthly rules are rejected",
        arguments: [
            (0, 15, RecurrenceRuleError.intervalShouldBeGraterThanZero(0)),
            (
                RecurrenceRule.monthlyIntervals.upperBound + 1, 15,
                RecurrenceRuleError.intervalShouldBeGraterThanZero(RecurrenceRule.monthlyIntervals.upperBound + 1)
            ),
            (1, 32, RecurrenceRuleError.dayOutOfRange(32)),
            (1, 0, RecurrenceRuleError.dayOutOfRange(0)),
        ]
    )
    func invalidMonthly(every: Int, day: Int, expected: RecurrenceRuleError) {
        expectError(expected) {
            _ = try RecurrenceRule(monthlyEvery: every, on: day)
        }
    }

    @Test(
        "Invalid yearly rules are rejected",
        arguments: [
            (0, 1, 1, RecurrenceRuleError.intervalShouldBeGraterThanZero(0)),
            (
                RecurrenceRule.yearlyIntervals.upperBound + 1, 1, 1,
                RecurrenceRuleError.intervalShouldBeGraterThanZero(RecurrenceRule.yearlyIntervals.upperBound + 1)
            ),
            (1, 13, 1, RecurrenceRuleError.monthOutOfRange(13)),
            (1, 0, 1, RecurrenceRuleError.monthOutOfRange(0)),
            (
                1, 2, 30,
                RecurrenceRuleError.monthDayIsOutOfMonth(month: 2, day: 30)
            ),
            (
                1, 4, 31,
                RecurrenceRuleError.monthDayIsOutOfMonth(month: 4, day: 31)
            ),
        ]
    )
    func invalidYearly(
        every: Int,
        month: Int,
        day: Int,
        expected: RecurrenceRuleError
    ) {
        expectError(expected) {
            _ = try RecurrenceRule(yearlyEvery: every, on: month, and: day)
        }
    }

    @Test("The largest allowed intervals are accepted")
    func intervalLimits() throws {
        let maxMonthly = RecurrenceRule.monthlyIntervals.upperBound
        let maxYearly = RecurrenceRule.yearlyIntervals.upperBound
        #expect(try RecurrenceRule(monthlyEvery: maxMonthly, on: 1).interval == maxMonthly)
        #expect(
            try RecurrenceRule(yearlyEvery: maxYearly, on: 1, and: 1).interval == maxYearly
        )
    }

    @Test("Feb 29 is a valid yearly anchor")
    func feb29Valid() throws {
        let rule = try RecurrenceRule(yearlyEvery: 1, on: 2, and: 29)
        #expect(rule.frequency == .yearly(month: 2, day: 29))
        #expect(rule.interval == 1)
    }
}

@Suite("Intervals and boundaries")
struct IntervalTests {
    @Test("Step 0 is the start's own period")
    func stepZero() throws {
        let start = day(2027, 1, 31)
        let rule = try RecurrenceRule(monthlyEvery: 1, on: 31)
        #expect(try rule.occurrence(0, from: start, in: calendar) == start)
    }

    @Test("Every 3 months crosses the year and still clamps")
    func quarterlyAcrossYear() throws {
        let start = day(2026, 11, 30)
        let rule = try RecurrenceRule(monthlyEvery: 3, on: 30)
        #expect(
            try rule.occurrence(1, from: start, in: calendar)
                == day(2027, 2, 28)
        )
        #expect(
            try rule.occurrence(2, from: start, in: calendar)
                == day(2027, 5, 30)
        )
    }

    @Test("Overdue quarterly skips missed quarters and keeps its cycle")
    func quarterlyOverdue() throws {
        let rule = try RecurrenceRule(monthlyEvery: 3, on: 15)
        let result = try rule.nextOccurrence(
            after: day(2026, 8, 20),
            from: day(2026, 1, 15),
            in: calendar
        )
        #expect(result == day(2026, 10, 15))
    }

    @Test("Every 2 years from Feb 29")
    func yearlyEveryTwo() throws {
        let start = day(2028, 2, 29)
        let rule = try RecurrenceRule(yearlyEvery: 2, on: 2, and: 29)
        #expect(
            try rule.occurrence(1, from: start, in: calendar)
                == day(2030, 2, 28)
        )
        #expect(
            try rule.occurrence(2, from: start, in: calendar)
                == day(2032, 2, 29)
        )
    }

    @Test("Yearly anchor comes from the rule, not the start date")
    func yearlyAnchorFromRule() throws {
        let rule = try RecurrenceRule(yearlyEvery: 1, on: 2, and: 29)
        #expect(
            try rule.occurrence(3, from: day(2029, 2, 28), in: calendar)
                == day(2032, 2, 29)
        )
    }
}

@Suite("Supported years")
struct SupportedYearsTests {
    @Test("The last supported year still works, one step past it throws")
    func lastSupportedYear() throws {
        let rule = try RecurrenceRule(monthlyEvery: 1, on: 31)
        let start = day(RecurrenceRule.supportedYears.upperBound, 11, 30)
        #expect(
            try rule.occurrence(1, from: start, in: calendar)
                == day(RecurrenceRule.supportedYears.upperBound, 12, 31)
        )
        expectError(.dateOutOfRange) {
            _ = try rule.occurrence(2, from: start, in: calendar)
        }
    }

    @Test("A date before the first supported year throws")
    func beforeFirstSupportedYear() throws {
        let rule = try RecurrenceRule(monthlyEvery: 1, on: 15)
        let start = day(RecurrenceRule.supportedYears.lowerBound, 1, 15)
        expectError(.dateOutOfRange) {
            _ = try rule.occurrence(-1, from: start, in: calendar)
        }
    }

    @Test(
        "Huge steps throw instead of returning a wrong date",
        arguments: [Int.max, Int.min, 1_000_000_000_000, 100_000]
    )
    func hugeSteps(step: Int) throws {
        let monthly = try RecurrenceRule(monthlyEvery: 1200, on: 15)
        let yearly = try RecurrenceRule(yearlyEvery: 100, on: 1, and: 15)
        expectError(.dateOutOfRange) {
            _ = try monthly.occurrence(
                step,
                from: day(2026, 1, 15),
                in: calendar
            )
        }
        expectError(.dateOutOfRange) {
            _ = try yearly.occurrence(
                step,
                from: day(2026, 1, 15),
                in: calendar
            )
        }
    }
    @Test("Overdue tasks from before 2026 still advance", arguments: [
        (true, (2024, 3, 1), (2027, 3, 1)),      // yearly on Mar 1
        (false, (2025, 11, 15), (2026, 10, 15)), // monthly on the 15th
    ])
    func overdueFromPast(yearly: Bool, due: (Int, Int, Int), expected: (Int, Int, Int)) throws {
        let rule = yearly ? try RecurrenceRule(yearlyEvery: 1, on: 3, and: 1)
                          : try RecurrenceRule(monthlyEvery: 1, on: 15)
        let result = try rule.nextOccurrence(after: day(2026, 9, 19), from: day(due.0, due.1, due.2), in: calendar)
        #expect(result == day(expected.0, expected.1, expected.2))
    }
}

@Suite("Time of day and time zones")
struct TimeTests {
    @Test("Completing late in the day compares by calendar day")
    func lateCompletion() throws {
        let completed = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 14,
                hour: 23,
                minute: 59
            )
        )!
        let rule = try RecurrenceRule(monthlyEvery: 1, on: 15)
        #expect(
            try rule.nextOccurrence(
                after: completed,
                from: day(2026, 6, 15),
                in: calendar
            ) == day(2026, 7, 15)
        )
    }

    @Test("A daylight-saving month still lands on midnight of the right day")
    func daylightSaving() throws {
        // Bucharest moves to summer time on 29 March 2026.
        let rule = try RecurrenceRule(monthlyEvery: 1, on: 31)
        let result = try rule.occurrence(
            2,
            from: day(2026, 1, 31),
            in: calendar
        )
        #expect(result == day(2026, 3, 31))
        #expect(calendar.component(.hour, from: result) == 0)
    }

    @Test(
        "Results don't depend on the time zone",
        arguments: [
            "Europe/Bucharest", "Pacific/Auckland", "America/Los_Angeles",
            "UTC",
        ]
    )
    func timeZones(identifier: String) throws {
        let zoned = Calendar.dueKit(
            timeZone: try #require(TimeZone(identifier: identifier))
        )
        let start = zoned.date(
            from: DateComponents(year: 2027, month: 1, day: 31)
        )!
        let rule = try RecurrenceRule.monthlyAnchored(to: start, in: zoned)
        let result = try rule.occurrence(1, from: start, in: zoned)
        #expect(
            zoned.dateComponents([.year, .month, .day], from: result)
                == DateComponents(year: 2027, month: 2, day: 28)
        )
    }
}
