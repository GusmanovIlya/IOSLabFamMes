import Foundation

enum ViewState: Equatable {
    case loading
    case empty
    case content
    case error(String)
}
