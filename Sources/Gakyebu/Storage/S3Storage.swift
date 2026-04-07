import Foundation
import CryptoKit

enum S3Error: LocalizedError {
    case httpError(Int, String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let body): return "S3 오류 \(code): \(body)"
        case .invalidURL:                    return "잘못된 S3 URL"
        }
    }
}

final class S3Storage: StorageManager {
    private let accessKey: String
    private let secretKey: String
    private let bucket: String
    private let region: String
    private let objectKey: String

    private var host: String { "\(bucket).s3.\(region).amazonaws.com" }
    private var baseURL: String { "https://\(host)/\(objectKey)" }

    init(accessKey: String, secretKey: String, bucket: String, region: String, objectKey: String) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.bucket    = bucket
        self.region    = region
        self.objectKey = objectKey
    }

    // MARK: - StorageManager

    func load() async throws -> AppData {
        let data = try await request(method: "GET", body: nil)
        if data.isEmpty { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppData.self, from: data)
    }

    func save(_ appData: AppData) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(appData)
        _ = try await request(method: "PUT", body: body)
    }

    // MARK: - AWS Signature Version 4

    private func request(method: String, body: Data?) async throws -> Data {
        guard let url = URL(string: baseURL) else { throw S3Error.invalidURL }

        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withYear, .withMonth, .withDay,
                                       .withTime, .withTimeZone, .withColonSeparatorInTime]
        let amzDate  = amzDateString(from: now)   // 20240101T000000Z
        let dateStamp = String(amzDate.prefix(8))  // 20240101

        let payload = body ?? Data()
        let payloadHash = SHA256.hash(data: payload).hexString

        // Canonical Request
        let signedHeaders = "content-type;host;x-amz-content-sha256;x-amz-date"
        let contentType   = method == "PUT" ? "application/json" : ""
        let canonicalHeaders =
            "content-type:\(contentType)\n" +
            "host:\(host)\n" +
            "x-amz-content-sha256:\(payloadHash)\n" +
            "x-amz-date:\(amzDate)\n"

        let canonicalRequest = [
            method,
            "/\(objectKey)",
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")

        // String to Sign
        let credentialScope = "\(dateStamp)/\(region)/s3/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            SHA256.hash(data: Data(canonicalRequest.utf8)).hexString
        ].joined(separator: "\n")

        // Signing Key
        let signingKey = signingKey(secretKey: secretKey, dateStamp: dateStamp, region: region, service: "s3")

        // Signature
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(stringToSign.utf8),
            using: SymmetricKey(data: signingKey)
        ).map { String(format: "%02x", $0) }.joined()

        // Authorization Header
        let authorization =
            "AWS4-HMAC-SHA256 " +
            "Credential=\(accessKey)/\(credentialScope), " +
            "SignedHeaders=\(signedHeaders), " +
            "Signature=\(signature)"

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.httpBody   = body
        urlRequest.setValue(contentType,  forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(host,         forHTTPHeaderField: "Host")
        urlRequest.setValue(payloadHash,  forHTTPHeaderField: "x-amz-content-sha256")
        urlRequest.setValue(amzDate,      forHTTPHeaderField: "x-amz-date")
        urlRequest.setValue(authorization, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 404 && method == "GET" { return Data() }
        guard (200..<300).contains(statusCode) else {
            throw S3Error.httpError(statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    // MARK: - Helpers

    private func amzDateString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        fmt.timeZone   = TimeZone(identifier: "UTC")
        return fmt.string(from: date)
    }

    private func signingKey(secretKey: String, dateStamp: String, region: String, service: String) -> Data {
        func hmac(_ data: Data, key: Data) -> Data {
            let code = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key))
            return Data(code)
        }
        let kSecret  = Data(("AWS4" + secretKey).utf8)
        let kDate    = hmac(Data(dateStamp.utf8), key: kSecret)
        let kRegion  = hmac(Data(region.utf8), key: kDate)
        let kService = hmac(Data(service.utf8), key: kRegion)
        return hmac(Data("aws4_request".utf8), key: kService)
    }
}

// MARK: - Digest hex helpers

private extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

