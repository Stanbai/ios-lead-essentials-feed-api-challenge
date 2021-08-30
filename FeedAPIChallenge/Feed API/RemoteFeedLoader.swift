//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }
			switch result {
			case .success(let (data, httpResponse)):
				completion(FeedImageMapper.map(data: data, from: httpResponse))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}

private enum FeedImageMapper {
	private struct Remote: Decodable {
		let items: [RemoteFeedImage]
		var feedImages: [FeedImage] {
			items.map { FeedImage(id: $0.image_id, description: $0.image_desc, location: $0.image_loc, url: $0.image_url) }
		}
	}

	private struct RemoteFeedImage: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL
	}

	static func map(data: Data, from httpResponse: HTTPURLResponse) -> FeedLoader.Result {
		guard httpResponse.statusCode == 200, let remoteItem = try? JSONDecoder().decode(Remote.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
		return .success(remoteItem.feedImages)
	}
}
