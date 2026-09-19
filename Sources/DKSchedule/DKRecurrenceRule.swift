//
//  DKRecurrenceRule.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation

public enum RecurrenceRule: Sendable, Equatable, Codable {
    case monthly(every: Int, day: Int)
    case yearly(every: Int, month: Int, day: Int)

}

extension RecurrenceRule {

}
//public struct RecurrenceRule: Equatable, Sendable {
//extension RecurrenceRule {
//    public enum Unit: Equatable, Sendable {
//        //no psecial cases for this
//        //        case  day
//        //        case week
//        case month
//        case year
//    }
//    public init(unit: Unit, interval: Int = 1, dayAnchor: Int, monthAnchor: Int? = nil) {
//        //preconditioning
//        precondition(interval >= 1, "interval must be at least 1")
//        precondition((1...31).contains(dayAnchor), "dayAnchor must be 1...31")
//        if let monthAnchor { precondition((1...12).contains(monthAnchor), "monthAnchor must be 1...12") }
//        if unit == .year { precondition(monthAnchor != nil, "yearly rules need monthAnchor") }
//
//        //init
//        self.unit = unit
//        self.interval = interval
//        self.dayAnchor = dayAnchor
//        self.monthAnchor = monthAnchor
//    }
//}

//convenient initialzers
extension RecurrenceRule {
    public init(monthlyEvery every: Int, on day: Int)
        throws(RecurrenceRuleError)
    {
        let rule = RecurrenceRule.monthly(every: every, day: day)
        //        guard rule.isValid else {
        //            return nil
        //        }
        try rule.validate()
        self = rule
    }
    public init(yearlyEvery every: Int, on month: Int, and day: Int)
        throws(RecurrenceRuleError)
    {
        let rule = RecurrenceRule.yearly(every: every, month: month, day: day)
        //        guard rule.isValid else {
        //            return nil
        //        }
        try rule.validate()
        self = rule
    }
}
//helpers
//Calendar to allow uage of different type of calendars. Tests whould be implemented
extension RecurrenceRule {
    //    public static func validate(toValidate: Int ) throws {
    //        guard toValidate>=1 else{ throw RecurrenceRuleError.intervalShouldBeGraterThanZero }
    //    }

    //Expand

    public func validate() throws(RecurrenceRuleError) {

        switch self {
        case .monthly(let every, let day):
            try generalThrow(every: every, day: day)
        case .yearly(let every, let month, let day):
            try generalThrow(every: every, day: day)
            guard (1...12).contains(month) else {
                throw .monthOutOfRange(month)
            }
            guard day <= Self.lastDayOfTheMonth(in: month) else {
                throw .monthDayIsOutOfMonth(month: month, day: day)
            }
        }
    }
    private func generalThrow(every: Int, day: Int) throws(RecurrenceRuleError)
    {
        guard every >= 1 else {
            throw .intervalShouldBeGraterThanZero(every)
        }
        guard (1...31).contains(day) else {
            throw .dayOutOfRange(day)
        }
    }
    public static func monthly(
        interval: Int = 1,
        anchoring date: Date,
        calendar: Calendar = Calendar.current
    ) -> RecurrenceRule {
        .monthly(
            every: interval,
            day: calendar.component(.day, from: date)
        )
        //        RecurrenceRule(unit: .month,
        //                       interval: interval,
        //                       dayAnchor: calendar.component(.day, from: date))
    }

    public static func yearly(
        interval: Int = 1,
        anchoring date: Date,
        calendar: Calendar = Calendar.current
    ) -> RecurrenceRule {
        .yearly(
            every: interval,
            month: calendar.component(.month, from: date),
            day: calendar.component(.day, from: date)
        )
        //        RecurrenceRule(unit: .year,
        //                       interval: interval,
        //                       dayAnchor: calendar.component(.day, from: date),
        //                       monthAnchor: calendar.component(.month, from: date))
    }

}
//Anchors
extension RecurrenceRule {
    public static func monthlyAnchored(
        to date: Date,
        every: Int = 1,
        in calendar: Calendar
    ) -> RecurrenceRule {
        .monthly(every: every, day: calendar.component(.day, from: date))
    }
    public static func yearlyAnchored(
        to date: Date,
        every: Int = 1,
        in calendar: Calendar
    ) -> RecurrenceRule {
        .yearly(
            every: every,
            month: calendar.component(.month, from: date),
            day: calendar.component(.day, from: date)
        )
    }
    private var dayAnchor: Int {
        switch self {
        case .monthly(every: _, let day),
            .yearly(every: _, month: _, let day):
            day
        }
    }
}
extension RecurrenceRule {
    public func occurrence(_ step: Int, from start: Date, in calendar: Calendar)
        -> Date?
    {
        guard isValid else {
            //Trowable with clear error here.
            return nil
        }
        var firstOfMonth: Date
        switch self {
        case .monthly(let every, day: _):
            //first make sure we dont obrain a overflow here
            let (_, overflow) = step.multipliedReportingOverflow(by: every)
            guard !overflow,
                let startMonth = calendar.dateInterval(of: .month, for: start)?
                    .start,
                let target = calendar.date(
                    byAdding: .month,
                    value: step * every,
                    to: startMonth
                )
            else {
                return nil
            }

            firstOfMonth = target

        case .yearly(let every, let month, day: _):
            let (years, overflow) = step.multipliedReportingOverflow(by: every)
            let (year, overflow2) = calendar.component(.year, from: start)
                .addingReportingOverflow(years)
            guard !overflow, !overflow2,
                let target = calendar.date(
                    from: DateComponents(year: year, month: month, day: 1)
                )
            else {
                return nil
            }
            firstOfMonth = target
        }
        guard
            let daysInMonth = calendar.range(
                of: .day,
                in: .month,
                for: firstOfMonth
            )?.count
        else {
            return nil
        }
        let day = min(dayAnchor, daysInMonth)
        return calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
    }
    public func nextOccurrence(
        after reference: Date,
        from start: Date,
        in calendar: Calendar
    ) -> Date? {
        let limit = calendar.startOfDay(for: max(reference, start))
        var step = 1
        while let candidate = occurrence(step, from: start, in: calendar) {
            if candidate > limit {
                return candidate
            }
            step += 1
        }
        return nil
    }
}
extension RecurrenceRule {
    //simple validation when need conditional
    public var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
        //        switch self {
        //        case let .monthly(every: every, day: day):
        //            return every >= 1 && (1...31).contains(day) //day can be any day. beecause it will float base on the month
        //        case let .yearly(every: every, month: month, day: day):
        //            guard every >= 1, (1...12).contains(month) else {
        //                return false;
        //            }
        //            return (1...Self.lastDayOfTheMonth(in: month)).contains(day)
        //        }
    }
    private static func lastDayOfTheMonth(in month: Int) -> Int {
        switch month {
        //TODO: Maybe add "in year" here.. will help in testability and also make sure the validatino is ok.
        case 2: return 29  //February....
        case 4, 6, 9, 11: return 30  //Fewer than 31...
        default: return 31
        }
    }
}
