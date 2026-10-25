//
//  APIErrorMapper.swift
//  AIChat2
//

import Foundation

nonisolated enum APIErrorMapper {

    static func error(statusCode: Int, headers: [AnyHashable: Any]) -> APIError? {
        switch statusCode {
            case 200..<300: nil
            case 401: APIError(kind: .unauthorized)
            case 402: APIError(kind: .paymentRequired)
            case 403: APIError(kind: .forbidden)
            case 404: APIError(kind: .notFound)
            case 422: APIError(kind: .validation)
            case 429: APIError(kind: .rateLimited, retryAfter: retryAfter(headers))
            case 500..<600: APIError(kind: .server)
            default: APIError(kind: .unknown)
        }
    }
    
    static func error(_ error: URLError) -> APIError {
        switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .timedOut,
                    .cannotFindHost, .cannotConnectToHost, .internationalRoamingOff:
                APIError(kind: .offline)
            default:
                APIError(kind: .unknown)
        }
    }
    
    private static func retryAfter(_ headers: [AnyHashable: Any]) -> Duration? {
        let value = headers.first { ($0.key as? String)?.lowercased() == "retry-after" }?.value as? String
        guard let seconds = value.flatMap({ Int($0.trimmingCharacters(in: .whitespaces)) }), seconds > 0 else {
            return nil
        }
        return .seconds(seconds)
    }
}
