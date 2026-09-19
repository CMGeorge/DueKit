//
//  DKRecurrenceRule.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation

//full change the structure. struct i belive is better having more control, specailly at initialisation
public struct RecurrenceRule: Sendable, Hashable {

    public enum Frequency: Hashable, Sendable {
        case monthly(day: Int)
        case yearly(month: Int, day: Int)
    }

    public let frequency: Frequency
    public let interval: Int

    public static let monthlyIntervals = 1...(12 * 100)
    public static let yearlyIntervals = 1...110
    public static let supportedYears = 2016...2126 //i dont see anyone using this code in 100 years, and 2016 just for old data to work
}

// MARK: - Life Cycle
extension RecurrenceRule {
    public init(_ frequency: Frequency, every interval: Int = 1)
        throws(RecurrenceRuleError)
    {
        try Self.validate(frequency, every: interval)
        self.frequency = frequency
        self.interval = interval
    }
    //conveninet contructors
    public init(monthlyEvery every: Int, on day: Int)
        throws(RecurrenceRuleError)
    {
        try self.init(.monthly(day: day), every: every)
    }
    public init(yearlyEvery every: Int, on month: Int, and day: Int)
        throws(RecurrenceRuleError)
    {
        try self.init(.yearly(month: month, day: day), every: every)
    }
}


//helpers
//Calendar to allow uage of different type of calendars. Tests whould be implemented
extension RecurrenceRule {
    //    public static func validate(toValidate: Int ) throws {
    //        guard toValidate>=1 else{ throw RecurrenceRuleError.intervalShouldBeGraterThanZero }
    //    }

    public static func validate(_ frequency: Frequency, every interval: Int)
        throws(RecurrenceRuleError)
    {
        switch frequency {
        case .monthly(let day):
            try generalThrow(
                every: interval,
                allowed: monthlyIntervals,
                day: day
            )
        case .yearly(let month, let day):
            try generalThrow(
                every: interval,
                allowed: yearlyIntervals,
                day: day
            )
            guard (1...12).contains(month) else {
                throw .monthOutOfRange(month)
            }
            guard day <= lastDayOfTheMonth(in: month) else {
                throw .monthDayIsOutOfMonth(month: month, day: day)
            }
        }
    }
    private static func generalThrow(
        every: Int,
        allowed: ClosedRange<Int>,
        day: Int
    ) throws(RecurrenceRuleError) {
        guard allowed.contains(every) else {
            throw .intervalShouldBeGraterThanZero(every)
        }
        guard (1...31).contains(day) else {
            throw .dayOutOfRange(day)
        }
    }
}
//Anchors
extension RecurrenceRule {
    public static func monthlyAnchored(
        to date: Date,
        every: Int = 1,
        in calendar: Calendar
    ) throws(RecurrenceRuleError) -> RecurrenceRule {
        try RecurrenceRule(
            .monthly(day: calendar.component(.day, from: date)),
            every: every
        )
    }
    public static func yearlyAnchored(
        to date: Date,
        every: Int = 1,
        in calendar: Calendar
    ) throws(RecurrenceRuleError) -> RecurrenceRule {
        try RecurrenceRule(
            .yearly(
                month: calendar.component(.month, from: date),
                day: calendar.component(.day, from: date)
            ),
            every: every
        )
    }
    private var dayAnchor: Int {
        switch frequency {
        case .monthly(let day), .yearly(_, let day):
            day
        }
    }
}
extension RecurrenceRule {
    public func occurrence(_ step: Int, from start: Date, in calendar: Calendar) throws(RecurrenceRuleError) -> Date {
        let offset = step.multipliedReportingOverflow(by: interval)
        guard !offset.overflow else { throw .dateOutOfRange }

        let year: Int
        let month: Int
        switch frequency {
        case .monthly:
            // Count months from year 0 so one addition moves across years.
            let startMonthIndex = calendar.component(.year, from: start) * 12 + calendar.component(.month, from: start) - 1
            let target = startMonthIndex.addingReportingOverflow(offset.partialValue)
            guard !target.overflow, target.partialValue >= 0 else { throw .dateOutOfRange }
            year = target.partialValue / 12
            month = target.partialValue % 12 + 1
        case .yearly(let anchorMonth, _):
            let target = calendar.component(.year, from: start).addingReportingOverflow(offset.partialValue)
            guard !target.overflow else { throw .dateOutOfRange }
            year = target.partialValue
            month = anchorMonth
        }

        guard Self.supportedYears.contains(year),
              let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count,
              let result = calendar.date(byAdding: .day, value: min(dayAnchor, daysInMonth) - 1, to: firstOfMonth)
        else { throw .dateOutOfRange }
        return result
    }

    public func nextOccurrence(
        after reference: Date,
        from start: Date,
        in calendar: Calendar
    ) throws(RecurrenceRuleError) -> Date {
        let limit = calendar.startOfDay(for: max(reference, start))
        let maxSteps = Self.supportedYears.count * 12
        var step = 1
        while step <= maxSteps {
            let candidate = try occurrence(step, from: start, in: calendar)
            if candidate > limit { return candidate }
            step += 1
        }
        throw .dateOutOfRange
    }
}
extension RecurrenceRule {
    //simple validation when need conditional
//    public var isValid: Bool {
//        do {
//            try validate()
//            return true
//        } catch {
//            return false
//        }
//        //        switch self {
//        //        case let .monthly(every: every, day: day):
//        //            return every >= 1 && (1...31).contains(day) //day can be any day. beecause it will float base on the month
//        //        case let .yearly(every: every, month: month, day: day):
//        //            guard every >= 1, (1...12).contains(month) else {
//        //                return false;
//        //            }
//        //            return (1...Self.lastDayOfTheMonth(in: month)).contains(day)
//        //        }
//    }
    private static func lastDayOfTheMonth(in month: Int) -> Int {
        switch month {
        //TODO: Maybe add "in year" here.. will help in testability and also make sure the validatino is ok.
        case 2: return 29  //February....
        case 4, 6, 9, 11: return 30  //Fewer than 31...
        default: return 31
        }
    }
}
