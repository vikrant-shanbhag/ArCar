import Vision
import CoreML

class WheelDetectionService {
    private var model: VNCoreMLModel

    init() {
        guard let mlModel = try? VNCoreMLModel(for: WheelDetector().model) else {
            fatalError("Failed to load WheelDetector model.")
        }
        self.model = mlModel
    }

    func detect(on request: Request, completion: @escaping (Result<[Response], Error>) -> Void) {
        let visionRequest = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion(.failure(RecognitionError.resultIsEmpty))
                return
            }

            // Filter results with confidence above threshold and map them to Response objects
            let filteredResults = results.filter { $0.confidence > 0.8 }
            let responses = filteredResults.map { result in
                Response(boundingBox: result.boundingBox, classification: "Wheel", confidence: result.confidence)
            }

            if responses.isEmpty {
                completion(.failure(RecognitionError.resultIsEmpty))
            } else {
                completion(.success(responses))
            }
        }

        visionRequest.imageCropAndScaleOption = .scaleFill

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: request.pixelBuffer, options: [:])
        do {
            try imageRequestHandler.perform([visionRequest])
        } catch {
            completion(.failure(error))
        }
    }

    struct Request {
        let pixelBuffer: CVPixelBuffer
    }

    struct Response {
        let boundingBox: CGRect
        let classification: String
        let confidence: Float
    }

    enum RecognitionError: Error {
        case resultIsEmpty
    }
}
