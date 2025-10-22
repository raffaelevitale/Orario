//
//  AppError.swift
//  Vallauri_da_Vincenzo
//
//  Created on 22/10/2025
//  Centralized error handling system
//

import Foundation

/// Centralized error types for the application
enum AppError: LocalizedError {
    // Data errors
    case invalidTimeFormat(String)
    case dataCorrupted(String)
    case decodingFailed(Error)
    case encodingFailed(Error)

    // Notification errors
    case notificationSchedulingFailed(Error)
    case notificationPermissionDenied
    case notificationUnavailable

    // Cache errors
    case cacheReadFailed
    case cacheWriteFailed
    case cacheExpired

    // Live Activity errors
    case liveActivityNotSupported
    case liveActivityUpdateFailed(Error)

    // Network/API errors (for future use)
    case networkUnavailable
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        // Data errors
        case .invalidTimeFormat(let time):
            return "Formato orario non valido: \(time)"
        case .dataCorrupted(let details):
            return "Dati corrotti: \(details)"
        case .decodingFailed(let error):
            return "Errore durante la lettura dei dati: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Errore durante il salvataggio dei dati: \(error.localizedDescription)"

        // Notification errors
        case .notificationSchedulingFailed(let error):
            return "Impossibile programmare la notifica: \(error.localizedDescription)"
        case .notificationPermissionDenied:
            return "Permessi notifiche negati. Abilitali nelle Impostazioni."
        case .notificationUnavailable:
            return "Le notifiche non sono disponibili su questo dispositivo"

        // Cache errors
        case .cacheReadFailed:
            return "Errore durante la lettura della cache"
        case .cacheWriteFailed:
            return "Errore durante la scrittura nella cache"
        case .cacheExpired:
            return "Cache scaduta"

        // Live Activity errors
        case .liveActivityNotSupported:
            return "Le Live Activities non sono supportate su questo dispositivo"
        case .liveActivityUpdateFailed(let error):
            return "Impossibile aggiornare la Live Activity: \(error.localizedDescription)"

        // Network errors
        case .networkUnavailable:
            return "Connessione di rete non disponibile"
        case .apiError(let statusCode, let message):
            return "Errore server (\(statusCode)): \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidTimeFormat:
            return "Verifica il formato dell'orario (deve essere HH:mm)"
        case .dataCorrupted:
            return "Prova a ripristinare i dati dalle impostazioni"
        case .decodingFailed, .encodingFailed:
            return "Prova a riavviare l'app. Se il problema persiste, contatta il supporto."
        case .notificationPermissionDenied:
            return "Vai in Impostazioni > Notifiche > Vallauri per abilitare le notifiche"
        case .notificationSchedulingFailed, .notificationUnavailable:
            return "Verifica le impostazioni delle notifiche"
        case .cacheReadFailed, .cacheWriteFailed, .cacheExpired:
            return "La cache verrà rigenerata automaticamente"
        case .liveActivityNotSupported:
            return "Le Live Activities richiedono iOS 16.1 o superiore"
        case .liveActivityUpdateFailed:
            return "Prova a riavviare la Live Activity"
        case .networkUnavailable:
            return "Verifica la tua connessione internet"
        case .apiError:
            return "Riprova più tardi. Se il problema persiste, contatta il supporto."
        }
    }
}

/// Result type alias per operazioni che possono fallire
typealias AppResult<T> = Result<T, AppError>
