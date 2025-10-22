//
//  DateFormatter+Extensions.swift
//  Vallauri_da_Vincenzo
//
//  Created on 22/10/2025
//  Performance optimization: Static cached DateFormatter instances
//

import Foundation

extension DateFormatter {
    /// Cached time formatter (HH:mm format)
    /// Use this instead of creating new DateFormatter instances
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Cached Italian date formatter (EEEE, d MMMM yyyy format)
    /// Example: "lunedì, 22 ottobre 2025"
    static let italianDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter
    }()

    /// Cached short Italian date formatter (EEEE d MMMM format)
    /// Example: "lunedì 22 ottobre"
    static let italianShortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter
    }()

    /// Cached numeric date formatter (dd/MM format)
    /// Example: "22/10"
    static let numericDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter
    }()

    /// Cached weekday formatter (EEEE format)
    /// Example: "lunedì"
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// Cached short date with month formatter (dd MMM format)
    /// Example: "22 ott"
    static let shortDateMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd MMM"
        return formatter
    }()
}
