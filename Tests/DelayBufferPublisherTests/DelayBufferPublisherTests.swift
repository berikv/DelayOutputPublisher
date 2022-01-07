import XCTest
import Combine
@testable import DelayBufferPublisher

final class DelayBufferPublisherTests: XCTestCase {
    func testExample() throws {
        let expectation = XCTestExpectation(description: "foo")

        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short


        let cancellable = Timer.publish(every: 1.0, on: .main, in: .default)
            .autoconnect()
            .handleEvents(receiveOutput: { date in
                print("Sending Timestamp \'\(df.string(from: date))\' to delay()")
            })
            .delay(for: .seconds(3), scheduler: RunLoop.main, options: .none)
            .delayBuffer()

            .sink(
                receiveCompletion: {
                    print("completion: \($0)")
                    expectation.fulfill()
                },
                receiveValue: { value in
                    let now = Date()


                    print("At \(df.string(from: now)) received  Timestamp \'\(df.string(from: value))\' sent: \(String(format: "%.4f", now.timeIntervalSince(value))) secs ago")
                }
            )

        wait(for: [expectation], timeout: 20)
    }

    func testDelay() throws {
        let expectation = XCTestExpectation(description: "foo")

        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium

        let c = (0..<10).publisher
            .delayBuffer()
            .sink(
                receiveCompletion: {
                    print("completion: \($0)")
                    expectation.fulfill()
                },
                receiveValue: { value in
                    let now = Date()
                    print("Received \(value) at \(df.string(from: now))")
                }
            )

        wait(for: [expectation], timeout: 20)
    }
}
