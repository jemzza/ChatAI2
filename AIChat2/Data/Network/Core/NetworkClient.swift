import Foundation
import Alamofire

nonisolated protocol NetworkClient: Sendable {
    func data(for endpoint: Endpoint) async throws -> Data
}

nonisolated extension NetworkClient {
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let data = try await data(for: endpoint)
        do {
            return try JSONDecoder.snakeCase.decode(T.self, from: data)
        } catch {
            throw APIError(kind: .decoding)
        }
    }
}

nonisolated final class AFNetworkClient: NetworkClient {
    
    private let baseURL: URL
    private let session: Session
    
    init(baseURL: URL, session: Session) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func data(for endpoint: Endpoint) async throws -> Data {
        let response = await makeRequest(endpoint)
            .validate()
            .serializingData(automaticallyCancelling: true)
            .response
        
        switch response.result {
            case .success(let data):
                return data
            case .failure(let error):
                throw error.asAPIError(response: response.response)
        }
    }
    
    private func makeRequest(_ endpoint: Endpoint) -> DataRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        let method = Alamofire.HTTPMethod(rawValue: endpoint.method.rawValue)
        let encoding = URLEncoding(destination: .queryString)
        let parameters = Dictionary(endpoint.query.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
        
        switch endpoint.body {
            case .none:
                return session.request(url, method: method, parameters: parameters, encoding: encoding)
            case .json(let data):
                return session.request(url, method: method, parameters: parameters, encoding: encoding) {
                    $0.httpBody = data
                    $0.headers.add(.contentType("application/json"))
                }
            case .multipart(let body):
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = endpoint.query.isEmpty ? nil : endpoint.query
                
                return session.upload(multipartFormData: { multipartFormData in
                    for (name, value) in body.fields {
                        multipartFormData.append(Data(value.utf8), withName: name)
                    }
                    
                    for file in body.files {
                        multipartFormData.append(
                            file.data,
                            withName: file.name,
                            fileName: file.fileName,
                            mimeType: file.mimeType
                        )
                    }
                }, to: components?.url ?? url, method: method)
        }
    }
}
