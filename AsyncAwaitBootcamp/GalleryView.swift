//
//  GalleryView.swift
//  AsyncAwaitBootcamp
//
//  Created by Gopabandhu Dash on 01/08/23.
//

import SwiftUI

enum GalleryError: Error {
    case invalidUrlProvided
    case imageDownloadFailed
    
    var description: String {
        switch self {
        case .invalidUrlProvided:
            return "Invalid URL."
        case .imageDownloadFailed:
            return "Image Download Failed."
        }
    }
}

class GalleryDataService {
    
    let urlString = "https://picsum.photos/200/300"
    
    func downloadImage() async throws -> UIImage {
        guard let imageURL = URL(string: urlString) else { throw GalleryError.invalidUrlProvided }

        do {
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode >= 200 && response.statusCode < 300,
                  let image = UIImage(data: data) else {
                throw GalleryError.imageDownloadFailed
            }
            return image
        } catch {
            throw GalleryError.invalidUrlProvided
        }
    }
}

@MainActor
class GalleryViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    private let dataService = GalleryDataService()
    
    func fetchImage() async throws {
        self.images.append(try await dataService.downloadImage())
    }
    
    func getImage() async throws -> UIImage {
        return try await dataService.downloadImage()
    }
    
    func getImageUsingTaskGroup() async throws {
        self.images = try await withThrowingTaskGroup(of: UIImage?.self) { group in
            var images = [UIImage]()
            
            for _ in 0..<15 {
                group.addTask {
                    try? await self.dataService.downloadImage()
                }
            }
            
            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            
            return images
        }
    }
}

struct GalleryView: View {
    
    @StateObject private var viewModel = GalleryViewModel()
    private var columns = [GridItem(.flexible()), GridItem(.flexible())]
    @State private var errorDescription: String? = nil
    
    var body: some View {
        ZStack {
            
            if let errorDescription = errorDescription {
                Text(errorDescription)
            }
            
            if viewModel.images.isEmpty {
                ProgressView()
            }
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 120, height: 120)
                            .shadow(radius: 3, x: 0, y: 2)
                    }
                }
            }
        }
        .navigationTitle("Swift Concurrency 😎")
        .task {
            /// async await
            /*for _ in 0..<20 {
             do {
             try await viewModel.fetchImage()
             } catch {
             errorDescription = (error as? GalleryError)?.description
             }
             }*/
            ///async let
            /*async let image1 = viewModel.getImage()
            async let image2 = viewModel.getImage()
            async let image3 = viewModel.getImage()
            async let image4 = viewModel.getImage()
            async let image5 = viewModel.getImage()
            async let image6 = viewModel.getImage()
            async let image7 = viewModel.getImage()
            async let image8 = viewModel.getImage()
            
            do {
                let (fetchImage1,
                     fetchImage2,
                     fetchImage3,
                     fetchImage4,
                     fetchImage5,
                     fetchImage6,
                     fetchImage7,
                     fetchImage8) = await (try image1,
                                           try image2,
                                           try image3,
                                           try image4,
                                           try image5,
                                           try image6,
                                           try image7,
                                           try image8)
                self.viewModel.images.append(contentsOf: [fetchImage1,
                                                          fetchImage2,
                                                          fetchImage3,
                                                          fetchImage4,
                                                          fetchImage5,
                                                          fetchImage6,
                                                          fetchImage7,
                                                          fetchImage8])
            } catch {
                errorDescription = (error as? GalleryError)?.description
            }*/
            /// task group
            do {
                try await viewModel.getImageUsingTaskGroup()
            } catch {
                self.errorDescription = (error as? GalleryError)?.description
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GalleryView()
        }
    }
}
