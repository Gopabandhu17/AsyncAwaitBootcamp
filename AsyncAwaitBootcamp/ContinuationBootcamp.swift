//
//  ContinuationBootcamp.swift
//  AsyncAwaitBootcamp
//
//  Created by Gopabandhu Dash on 05/08/23.
//

import SwiftUI

class ContinuationDataService {
    
    let urlString = "https://picsum.photos/200/200"
    
    func downloadImage(completionHandler: @escaping (_ image: UIImage) -> Void) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                  response.statusCode >= 200 && response.statusCode < 300,
                  let data = data,
                  let image = UIImage(data: data) else { return }
            completionHandler(image)
        }.resume()
    }
    
    func downloadImageWithContinuation() async throws -> UIImage {
        guard let url = URL(string: urlString) else { throw GalleryError.invalidUrlProvided }
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data,
                   let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: GalleryError.imageDownloadFailed)
                }
            }
            .resume()
        }
    }
}

@MainActor
class ContinuationViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    let dataService = ContinuationDataService()
    
    func getImage() {
        dataService.downloadImage { [weak self] image in
            self?.image = image
        }
    }
    
    func getImageUsingContinuation() async throws {
        self.image = try await dataService.downloadImageWithContinuation()
    }
}

struct ContinuationBootcamp: View {
    
    @StateObject private var viewModel = ContinuationViewModel()
    
    var body: some View {
        ZStack {
            
            if viewModel.image == nil {
                ProgressView()
            }
            
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .clipShape(Circle())
            }
        }
        .task {
            do {
                try await viewModel.getImageUsingContinuation()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
}

struct ContinuationBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        ContinuationBootcamp()
    }
}
