//
//  ScheduleTests.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation
import Testing
import DKSchedule

@Test func unitTypeExistenceTest() {
//    let _: [RecurrenceRule.Unit] = [RecurrenceRule.Unit.month, RecurrenceRule.Unit.year]  //force compilation errro
}
@Test func `recurenceRuleIntervalOne`() {
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
    
}

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
    ])
    func invalid(rule: RecurrenceRule) {
        #expect(!rule.isValid)
    }

    @Test("Feb 29 is a valid yearly anchor")
    func feb29Valid() {
        #expect(RecurrenceRule(yearlyEvery: 1, on: 2, and: 29) != nil)
        #expect(RecurrenceRule(monthlyEvery: 0, on: 1) == nil)
    }

    @Test("Round-trips through Codable")
    func codable() throws {
        let rule = RecurrenceRule.yearly(every: 1, month: 2, day: 29)
        let data = try JSONEncoder().encode(rule)
        #expect(try JSONDecoder().decode(RecurrenceRule.self, from: data) == rule)
    }
}
