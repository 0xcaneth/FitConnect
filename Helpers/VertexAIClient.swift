import Foundation

// Define the structure for a message within the 'contents' array
struct VertexMessage: Codable {
    let text: String
}

// Update VertexGenerateRequest to include the 'contents' field
struct VertexGenerateRequest: Codable {
    let model: String
    let contents: [VertexMessage] // ADDED: This field is required by Vertex AI
}

// Assume accessToken is defined elsewhere and accessible in this scope
// For example: let accessToken = "YOUR_ACCESS_TOKEN"

func generateWithVertex(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
    // URL for Vertex AI generateContent endpoint
    // Remember to replace YOUR_PROJECT_ID with your actual project ID
    guard let url = URL(string: "https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/publishers/google/models/text-bison-001:generateContent") else {
        completion(.failure(NSError(domain: "VertexAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // Ensure accessToken is valid and available here
    // request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    // CORRECTED BODY:
    // Initialize VertexGenerateRequest with the model and the contents array.
    // The contents array will contain one VertexMessage with the provided prompt.
    let body = VertexGenerateRequest(
        model: "projects/YOUR_PROJECT_ID/locations/us-central1/publishers/google/models/text-bison-001", // Keep your model identifier
        contents: [VertexMessage(text: prompt)] // CHANGED: Added contents field
    )

    do {
        request.httpBody = try JSONEncoder().encode(body)
    } catch {
        completion(.failure(error))
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error {
            completion(.failure(error))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NSError(domain: "VertexAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage = "Server error: \(httpResponse.statusCode)"
            if let data, let errorString = String(data: data, encoding: .utf8) {
                errorMessage += "\nResponse: \(errorString)"
            }
            completion(.failure(NSError(domain: "VertexAIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        guard let data else {
            completion(.failure(NSError(domain: "VertexAIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            return
        }

        // Assuming the response contains JSON with the generated text.
        // You'll need to parse this according to the actual Vertex AI response structure.
        // For example, if it's a simple string:
        // if let generatedText = String(data: data, encoding: .utf8) {
        //     completion(.success(generatedText))
        // } else {
        //     completion(.failure(NSError(domain: "VertexAIClient", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"])))
        // }

        // Or if it's a more complex JSON object, you'd decode it:
        // struct VertexResponse: Codable { /* ... response fields ... */ }
        // do {
        //     let decodedResponse = try JSONDecoder().decode(VertexResponse.self, from: data)
        //     // Extract the relevant text from decodedResponse
        //     completion(.success("extracted text from response"))
        // } catch {
        //     completion(.failure(error))
        // }
        
        // For now, returning raw data as string for simplicity
        if let responseString = String(data: data, encoding: .utf8) {
             completion(.success(responseString))
        } else {
             completion(.failure(NSError(domain: "VertexAIClient", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response data"])))
        }

    }.resume()
}

// Example usage (you'll need to define accessToken and YOUR_PROJECT_ID):
/*
func testVertexAI() {
    // Ensure you have a valid accessToken
    // let accessToken = "YOUR_VALID_ACCESS_TOKEN"
    generateWithVertex(prompt: "Tell me a joke about programming.") { result in
        DispatchQueue.main.async {
            switch result {
            case .success(let responseText):
                print("Vertex AI Response: \(responseText)")
            case .failure(let error):
                print("Vertex AI Error: \(error.localizedDescription)")
            }
        }
    }
}
*/