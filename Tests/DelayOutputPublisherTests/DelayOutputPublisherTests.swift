import XCTest
import Combine
@testable import DelayOutputPublisher

final class DelayOutputPublisherTests: XCTestCase {
    func testDelay() throws {
        let expectation = XCTestExpectation()

        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium

        print("Start at \(df.string(from: Date()))")
        let cancellable = (0..<4).publisher
            .delayOutput(for: .seconds(1), scheduler: RunLoop.main)
            .sink(
                receiveCompletion: {
                    print("completed \($0)")
                    expectation.fulfill()
                },
                receiveValue: { value in
                    print("Received \(value) after \(df.string(from: Date()))")
                }
            )

        wait(for: [expectation], timeout: 20)
        _ = cancellable
    }
}
