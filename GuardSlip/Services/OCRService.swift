import Foundation
import Vision
import Combine

// MARK: - Protocol

protocol OCRServiceProtocol {
    func recognizeDate(from image: CGImage) -> AnyPublisher<Date?, Never>
}

// MARK: - Implementation

final class OCRService: OCRServiceProtocol {
    
    private let processingQueue = DispatchQueue(label: "com.guardslip.ocr", qos: .userInitiated)
    
    private static let dateFormats: [(regex: String, format: String)] = [
        (#"\d{2}\.\d{2}\.\d{4}"#, "dd.MM.yyyy"),
        (#"\d{2}/\d{2}/\d{4}"#, "MM/dd/yyyy"),
        (#"\d{2}-\d{2}-\d{4}"#, "dd-MM-yyyy"),
        (#"\d{4}-\d{2}-\d{2}"#, "yyyy-MM-dd"),
        (#"\d{2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{4}"#, "dd MMM yyyy"),
        (#"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2},?\s+\d{4}"#, "MMM dd, yyyy"),
    ]
    
    func recognizeDate(from image: CGImage) -> AnyPublisher<Date?, Never> {
        Future<Date?, Never> { [weak self] promise in
            guard let self else {
                promise(.success(nil))
                return
            }
            self.processingQueue.async {
                self.performRecognition(on: image) { date in
                    promise(.success(date))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private
    
    private func performRecognition(on image: CGImage, completion: @escaping (Date?) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            
            let parsedDate = self.extractMostRecentDate(from: recognizedText)
            completion(parsedDate)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
    
    private func extractMostRecentDate(from text: String) -> Date? {
        var dates: [Date] = []
        let now = Date()
        
        for (pattern, format) in Self.dateFormats {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            
            for match in matches {
                guard let matchRange = Range(match.range, in: text) else { continue }
                var dateString = String(text[matchRange])
                
                if format == "MMM dd, yyyy" {
                    dateString = dateString.replacingOccurrences(of: ",", with: "")
                    formatter.dateFormat = "MMM dd yyyy"
                }
                
                if let date = formatter.date(from: dateString), date <= now {
                    dates.append(date)
                }
                
                formatter.dateFormat = format
            }
        }
        
        for (pattern, _) in Self.dateFormats where pattern.contains("MM/dd") {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            let altFormatter = DateFormatter()
            altFormatter.locale = Locale(identifier: "en_US_POSIX")
            altFormatter.dateFormat = "dd/MM/yyyy"
            
            for match in matches {
                guard let matchRange = Range(match.range, in: text) else { continue }
                let dateString = String(text[matchRange])
                if let date = altFormatter.date(from: dateString), date <= now {
                    dates.append(date)
                }
            }
        }
        
        return dates.max()
    }
}
