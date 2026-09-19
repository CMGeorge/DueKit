//
//  CrashTests.swift
//  DueKit
//
//  Calls that must never bring the host app down. Each one runs in a child
//  process, so a crash fails that test instead of stopping the whole run.
//  Exit tests are only supported on macOS, so run these with `swift test`.
//

#if os(macOS)
import Foundation
import Testing
import DKSchedule

@Suite("Must not crash")
struct CrashTests {
    @Test("nextOccurrence with an invalid rule does not crash")
    func nextOccurrenceInvalidRule() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
            _ = RecurrenceRule.monthly(every: 0, day: 15)
                .nextOccurrence(after: start, from: start, in: calendar)
        }
    }

    @Test("occurrence with a huge monthly interval does not crash")
    func occurrenceHugeMonthlyInterval() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
            _ = RecurrenceRule.monthly(every: Int.max, day: 15)
                .occurrence(2, from: start, in: calendar)
        }
    }

    @Test("occurrence with a huge yearly interval does not crash")
    func occurrenceHugeYearlyInterval() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
            _ = RecurrenceRule.yearly(every: Int.max / 2, month: 1, day: 15)
                .occurrence(1, from: start, in: calendar)
        }
    }

    @Test("occurrence far beyond the calendar's range does not crash")
    func occurrenceFarFuture() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
            _ = RecurrenceRule.yearly(every: 1_000_000_000, month: 1, day: 15)
                .occurrence(1_000, from: start, in: calendar)
        }
    }

    @Test("nextOccurrence with a distant-future reference finishes")
    func nextOccurrenceDistantFuture() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
            _ = RecurrenceRule.monthly(every: 1, day: 15)
                .nextOccurrence(after: .distantFuture, from: start, in: calendar)
        }
    }

    @Test("A negative step does not crash")
    func negativeStep() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))!
            _ = RecurrenceRule.monthly(every: 1, day: 31)
                .occurrence(-1, from: start, in: calendar)
        }
    }

    @Test("A non-Gregorian calendar passed by mistake does not crash")
    func nonGregorianCalendar() async {
        await #expect(processExitsWith: .success) {
            var calendar = Calendar(identifier: .hebrew)
            calendar.timeZone = TimeZone(identifier: "UTC")!
            let start = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
                .date(from: DateComponents(year: 2026, month: 1, day: 31))!
            _ = RecurrenceRule.monthly(every: 1, day: 31)
                .occurrence(1, from: start, in: calendar)
        }
    }
}
#endif
