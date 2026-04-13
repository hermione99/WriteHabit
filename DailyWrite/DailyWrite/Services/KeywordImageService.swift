import Foundation
import FirebaseFirestore
import SwiftUI
import FirebaseFirestore
import SwiftUI

struct KeywordImageService {
    static let shared = KeywordImageService()
    
    private let unsplashAccessKey = "YOUR_UNSPLASH_ACCESS_KEY"
    private let imageCache = NSCache<NSString, NSData>()
    
    // Get a matching image URL for a keyword
    func getImageURL(for keyword: String, language: AppLanguage) async throws -> URL? {
        // First check cache
        let cacheKey = "\(keyword)_\(language.rawValue)" as NSString
        if let cachedData = imageCache.object(forKey: cacheKey),
           let urlString = String(data: cachedData as Data, encoding: .utf8),
           let url = URL(string: urlString) {
            return url
        }
        
        // Use curated images (reliable, no API needed)
        if let curatedURL = getCuratedImageURL(for: keyword) {
            // Cache it
            if let urlData = curatedURL.absoluteString.data(using: .utf8) {
                imageCache.setObject(urlData as NSData, forKey: cacheKey)
            }
            return curatedURL
        }
        
        // Fallback: Use Unsplash Source API with translated keyword
        let searchTerm = translateForImageSearch(keyword)
        let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "nature"
        let unsplashURL = URL(string: "https://source.unsplash.com/800x600/?\(encodedTerm)")
        
        // Cache the fallback URL too
        if let url = unsplashURL, let urlData = url.absoluteString.data(using: .utf8) {
            imageCache.setObject(urlData as NSData, forKey: cacheKey)
        }
        
        return unsplashURL
    }
    
    // Curated image URLs for keywords
    func getCuratedImageURL(for keyword: String) -> URL? {
        let curatedImages: [String: String] = [
            // Korean keywords
            "우연한 발견": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800",
            "메아리": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
            "방랑": "https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=800",
            "그림자": "https://images.unsplash.com/photo-1515549832467-8783363e19b6?w=800",
            "표류": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
            "만개": "https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=800",
            "침묵": "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800",
            "노을": "https://images.unsplash.com/photo-1500964757637-c85e8a162699?w=800",
            "안개": "https://images.unsplash.com/photo-1485236715568-ddc5ee6ca227?w=800",
            "고요": "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800",
            "산책": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
            "추억": "https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=800",
            "꿈": "https://images.unsplash.com/photo-1496568816309-51d7c20c3f21?w=800",
            "빛": "https://images.unsplash.com/photo-1507400492013-162706c8c05e?w=800",
            "파도": "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=800",
            "바람": "https://images.unsplash.com/photo-1534088568595-a066f410bcda?w=800",
            "비": "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=800",
            "눈": "https://images.unsplash.com/photo-1491002052546-bf38f186af56?w=800",
            "새벽": "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800",
            "황혼": "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800",
            
            // English keywords
            "Serendipity": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800",
            "Echo": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
            "Wanderlust": "https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=800",
            "Shadows": "https://images.unsplash.com/photo-1515549832467-8783363e19b6?w=800",
            "Drift": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
            "Bloom": "https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=800",
            "Silence": "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800",
            "Sunset": "https://images.unsplash.com/photo-1500964757637-c85e8a162699?w=800",
            "Mist": "https://images.unsplash.com/photo-1485236715568-ddc5ee6ca227?w=800",
            "Quiet": "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800",
            "Stroll": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
            "Memory": "https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=800",
            "Dream": "https://images.unsplash.com/photo-1496568816309-51d7c20c3f21?w=800",
            "Light": "https://images.unsplash.com/photo-1507400492013-162706c8c05e?w=800",
            "Waves": "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=800",
            "Wind": "https://images.unsplash.com/photo-1534088568595-a066f410bcda?w=800",
            "Rain": "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=800",
            "Snow": "https://images.unsplash.com/photo-1491002052546-bf38f186af56?w=800",
            "Dawn": "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800",
            "Dusk": "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800"
        ]
        
        if let urlString = curatedImages[keyword] {
            return URL(string: urlString)
        }
        
        return URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800")
    }
    
    // Translate Korean keywords to English for image search
    private func translateForImageSearch(_ koreanKeyword: String) -> String {
        let translations: [String: String] = [
            "우연한 발견": "serendipity",
            "메아리": "echo",
            "방랑": "wanderlust",
            "그림자": "shadow",
            "표류": "drift",
            "만개": "bloom",
            "침묵": "silence",
            "노을": "sunset",
            "안개": "mist",
            "고요": "quiet",
            "산책": "walk",
            "추억": "memory",
            "꿈": "dream",
            "빛": "light",
            "파도": "waves",
            "바람": "wind",
            "비": "rain",
            "눈": "snow",
            "새벽": "dawn",
            "황혼": "dusk"
        ]
        return translations[koreanKeyword] ?? koreanKeyword
    }
}

// AsyncImage with loading state
struct KeywordImageView: View {
    let keyword: String
    let language: AppLanguage
    @State private var imageURL: URL?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackView
                    @unknown default:
                        loadingView
                    }
                }
            } else {
                loadingView
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private var loadingView: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
            )
    }
    
    private var fallbackView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private func loadImage() async {
        do {
            imageURL = try await KeywordImageService.shared.getImageURL(for: keyword, language: language)
        } catch {
            imageURL = KeywordImageService.shared.getCuratedImageURL(for: keyword)
        }
        isLoading = false
    }
}
