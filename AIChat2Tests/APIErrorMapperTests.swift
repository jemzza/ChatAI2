import Foundation
import Testing
@testable import AIChat2

struct APIErrorMapperTests {
    @Test(arguments: [
        (401, ErrorKind.unauthorized),
        (402, .paymentRequired),
        (403, .forbidden),
        (404, .notFound),
        (422, .validation),
        (503, .server),
        (418, .unknown)
    ])
    func mapsStatusCodes(status: Int, kind: ErrorKind) {
        #expect(APIErrorMapper.error(statusCode: status, headers: [:])?.kind == kind)
    }
    
    @Test func successHasNoError() {
        #expect(APIErrorMapper.error(statusCode: 200, headers: [:]) == nil)
    }
    
    @Test func rateLimitKeepsRetryAfter() {
        let error = APIErrorMapper.error(statusCode: 429, headers: ["Retry-After": "30"])
        #expect(error == APIError(kind: .rateLimited, retryAfter: .seconds(30)))
    }
    
    @Test func connectionProblemsAreOffline() {
        #expect(APIErrorMapper.error(URLError(.notConnectedToInternet)).kind == .offline)
        #expect(APIErrorMapper.error(URLError(.timedOut)).kind == .offline)
        #expect(APIErrorMapper.error(URLError(.badServerResponse)).kind == .unknown)
    }
}
