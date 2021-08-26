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
		client.get(from: url) { result in
			switch result {
			case .success(let (data, httpResponse)):
				completion(FeedImageMapper.map(data: data, from: httpResponse))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}

final class FeedImageMapper {
	private struct RemoteObj: Decodable {
		var items: [RemoteFeedImage]
		var feedImages: [FeedImage] {
			items.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
		}
	}

	private struct RemoteFeedImage: Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL
	}

	static func map(data: Data, from httpResponse: HTTPURLResponse) -> FeedLoader.Result {
		guard httpResponse.statusCode == 200, let remoteItem = try? JSONDecoder().decode(RemoteObj.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
		return .success(remoteItem.feedImages)
	}
}
