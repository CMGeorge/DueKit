//
//  CrashTests.swift
//  DueKit
//
//  Calls that must never bring the host app down. Each one runs in a child
//  process, so a crash fails that test instead of stopping the whole run.
//  Exit tests are only supported on macOS, so run these with `swift test`.
//  `try?` is deliberate: these tests only check that the process survives.
//

#if os(macOS)
import Foundation
import Testing
import DKSchedule

@Suite("Must not crash")
struct CrashTests {
    @Test("An invalid rule is rejected without crashing")
    func invalidRule() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
            _ = try? RecurrenceRule(monthlyEvery: 0, on: 15)
                .nextOccurrence(after: start, from: start, in: calendar)
        }
    }

    @Test("Huge intervals are rejected without crashing")
    func hugeIntervals() async {
        await #expect(processExitsWith: .success) {
            _ = try? RecurrenceRule(monthlyEvery: Int.max, on: 15)
            _ = try? RecurrenceRule(yearlyEvery: Int.max / 2, on: 1, and: 15)
            _ = try? RecurrenceRule(monthlyEvery: Int.min, on: 15)
        }
    }

    @Test("The largest valid intervals with huge steps do not crash")
    func hugeSteps() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
            for step in [Int.max, Int.min, Int.max / 2, 1_000_000] {
                _ = try? RecurrenceRule(monthlyEvery: 1200, on: 15).occurrence(step, from: start, in: calendar)
                _ = try? RecurrenceRule(yearlyEvery: 100, on: 1, and: 15).occurrence(step, from: start, in: calendar)
            }
        }
    }

    @Test("nextOccurrence with a distant-future reference finishes")
    func nextOccurrenceDistantFuture() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
            _ = try? RecurrenceRule(monthlyEvery: 1, on: 15)
                .nextOccurrence(after: .distantFuture, from: start, in: calendar)
        }
    }

    @Test("A negative step does not crash")
    func negativeStep() async {
        await #expect(processExitsWith: .success) {
            let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "UTC")!)
            let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))!
            _ = try? RecurrenceRule(monthlyEvery: 1, on: 31)
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
            _ = try? RecurrenceRule(monthlyEvery: 1, on: 31)
                .occurrence(1, from: start, in: calendar)
        }
    }
}
#endif
