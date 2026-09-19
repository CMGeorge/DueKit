//
//  ScheduleTests.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation
import Testing
import DKSchedule

//@Test func unitTypeExistenceTest() {
//    let _: [RecurrenceRule.Unit] = [RecurrenceRule.Unit.month, RecurrenceRule.Unit.year]  //force compilation errro
//}
//@Test func `recurenceRuleIntervalOne`() {
    //dest default rule
//    let ruleMDefault = RecurrenceRule(unit: .month , dayAnchor: 31)
//    
//    #expect(ruleMDefault.unit == .month)
//    #expect(ruleMDefault.interval == 1)
//    
//    let ruleM2 = RecurrenceRule(unit: .month,
//                               interval: 2,
//                                dayAnchor: 31)
//    #expect(ruleM2.unit == .month)
//    #expect(ruleM2.interval == 2)
    
//}

private let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "Europe/Bucharest")!)

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

@Suite("Month-end anchoring")
struct MonthEndTests {
    @Test("Jan 31 monthly keeps its anchor", arguments: [
        (2025, 1, (2025, 2, 28)),
        (2025, 2, (2025, 3, 31)),
        (2025, 3, (2025, 4, 30)),
        (2024, 1, (2024, 2, 29)),
    ])
    func jan31(startYear: Int, step: Int, expected: (Int, Int, Int)) {
        let start = day(startYear, 1, 31)
        let rule = RecurrenceRule.monthlyAnchored(to: start, in: calendar)
        #expect(rule.occurrence(step, from: start, in: calendar) == day(expected.0, expected.1, expected.2))
    }

    @Test("Feb 29 yearly falls on Feb 28, then returns in leap years")
    func feb29() {
        let start = day(2024, 2, 29)
        let rule = RecurrenceRule.yearlyAnchored(to: start, in: calendar)
        #expect(rule.occurrence(1, from: start, in: calendar) == day(2025, 2, 28))
        #expect(rule.occurrence(4, from: start, in: calendar) == day(2028, 2, 29))
    }
}

@Suite("Completion")
struct CompletionTests {
    let due = day(2026, 6, 15)
    let rule = RecurrenceRule.monthly(every: 1, day: 15)

    @Test("Next due date after completing", arguments: [
        ((2026, 6, 10), (2026, 7, 15)),
        ((2026, 6, 15), (2026, 7, 15)),
        ((2026, 8, 20), (2026, 9, 15)),
        ((2026, 7, 15), (2026, 8, 15)),
    ])
    func next(completed: (Int, Int, Int), expected: (Int, Int, Int)) {
        let result = rule.nextOccurrence(after: day(completed.0, completed.1, completed.2), from: due, in: calendar)
        #expect(result == day(expected.0, expected.1, expected.2))
    }
}

@Suite("Validation")
struct ValidationTests {
    @Test("Invalid rules are rejected", arguments: [
        RecurrenceRule.monthly(every: 0, day: 15),
        .monthly(every: 1, day: 32),
        .yearly(every: 1, month: 2, day: 30),
        .yearly(every: 1, month: 13, day: 1),
        .monthly(every: 1, day: 0),
        .yearly(every: 0, month: 1, day: 1),
        .yearly(every: 1, month: 4, day: 31),
        .yearly(every: 1, month: 0, day: 1),
    ])
    func invalid(rule: RecurrenceRule) {
        #expect(!rule.isValid)
    }

    @Test("Feb 29 is a valid yearly anchor")
    func feb29Valid() throws {
//        #expect(RecurrenceRule(yearlyEvery: 1, on: 2, and: 29) != nil)
//        #expect(RecurrenceRule(monthlyEvery: 0, on: 1) == nil)
        let rule = try RecurrenceRule(yearlyEvery: 1, on: 2, and: 29)
        #expect(rule == .yearly(every: 1, month: 2, day: 29))
        
    }

    @Test("Round-trips through Codable")
    func codable() throws {
        let rule = RecurrenceRule.yearly(every: 1, month: 2, day: 29)
        let data = try JSONEncoder().encode(rule)
        #expect(try JSONDecoder().decode(RecurrenceRule.self, from: data) == rule)
    }

    @Test("Stored format stays stable", arguments: [
        (RecurrenceRule.monthly(every: 1, day: 31), #"{"monthly":{"day":31,"every":1}}"#),
        (.yearly(every: 2, month: 2, day: 29), #"{"yearly":{"day":29,"every":2,"month":2}}"#),
    ])
    func storedFormat(rule: RecurrenceRule, json: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(String(decoding: try encoder.encode(rule), as: UTF8.self) == json)
    }
}

@Suite("Intervals and boundaries")
struct IntervalTests {
    @Test("Step 0 is the start's own period")
    func stepZero() {
        let start = day(2025, 1, 31)
        let rule = RecurrenceRule.monthly(every: 1, day: 31)
        #expect(rule.occurrence(0, from: start, in: calendar) == start)
    }

    @Test("Every 3 months crosses the year and still clamps")
    func quarterlyAcrossYear() {
        let start = day(2025, 11, 30)
        let rule = RecurrenceRule.monthly(every: 3, day: 30)
        #expect(rule.occurrence(1, from: start, in: calendar) == day(2026, 2, 28))
        #expect(rule.occurrence(2, from: start, in: calendar) == day(2026, 5, 30))
    }

    @Test("Overdue quarterly skips missed quarters and keeps its cycle")
    func quarterlyOverdue() {
        let rule = RecurrenceRule.monthly(every: 3, day: 15)
        let result = rule.nextOccurrence(after: day(2026, 8, 20), from: day(2026, 1, 15), in: calendar)
        #expect(result == day(2026, 10, 15))
    }

    @Test("Every 2 years from Feb 29")
    func yearlyEveryTwo() {
        let start = day(2024, 2, 29)
        let rule = RecurrenceRule.yearly(every: 2, month: 2, day: 29)
        #expect(rule.occurrence(1, from: start, in: calendar) == day(2026, 2, 28))
        #expect(rule.occurrence(2, from: start, in: calendar) == day(2028, 2, 29))
    }

    @Test("Yearly anchor comes from the rule, not the start date")
    func yearlyAnchorFromRule() {
        let rule = RecurrenceRule.yearly(every: 1, month: 2, day: 29)
        #expect(rule.occurrence(3, from: day(2025, 2, 28), in: calendar) == day(2028, 2, 29))
    }
}

@Suite("Time of day and time zones")
struct TimeTests {
    @Test("Completing late in the day compares by calendar day")
    func lateCompletion() {
        let completed = calendar.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 23, minute: 59))!
        let rule = RecurrenceRule.monthly(every: 1, day: 15)
        #expect(rule.nextOccurrence(after: completed, from: day(2026, 6, 15), in: calendar) == day(2026, 7, 15))
    }

    @Test("A daylight-saving month still lands on midnight of the right day")
    func daylightSaving() throws {
        // Bucharest moves to summer time on 29 March 2026.
        let rule = RecurrenceRule.monthly(every: 1, day: 31)
        let result = try #require(rule.occurrence(2, from: day(2026, 1, 31), in: calendar))
        #expect(result == day(2026, 3, 31))
        #expect(calendar.component(.hour, from: result) == 0)
    }

    @Test("Results don't depend on the time zone", arguments: [
        "Europe/Bucharest", "Pacific/Auckland", "America/Los_Angeles", "UTC",
    ])
    func timeZones(identifier: String) throws {
        let zoned = Calendar.dueKit(timeZone: try #require(TimeZone(identifier: identifier)))
        let start = zoned.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let rule = RecurrenceRule.monthlyAnchored(to: start, in: zoned)
        let result = try #require(rule.occurrence(1, from: start, in: zoned))
        #expect(zoned.dateComponents([.year, .month, .day], from: result) == DateComponents(year: 2025, month: 2, day: 28))
    }
}
