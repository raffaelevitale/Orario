//
//  DateExtensions.swift
//  OrarioScuolaApp
//

import Foundation

extension Date {
    func startOfWeek(using calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    func endOfWeek(using calendar: Calendar = Calendar.current) -> Date {
        let startOfWeek = self.startOfWeek(using: calendar)
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    func startOfMonth(using calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    func endOfMonth(using calendar: Calendar = Calendar.current) -> Date {
        let startOfMonth = self.startOfMonth(using: calendar)
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: self)
    }

    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    var year: Int {
        Calendar.current.component(.year, from: self)
    }
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day ?? 0
    }
    
    func isToday(_ date: Date) -> Bool {
        return isDate(date, inSameDayAs: Date())
    }
    
    func isYesterday(_ date: Date) -> Bool {
        guard let yesterday = self.date(byAdding: .day, value: -1, to: Date()) else {
            return false
        }
        return isDate(date, inSameDayAs: yesterday)
    }
}
