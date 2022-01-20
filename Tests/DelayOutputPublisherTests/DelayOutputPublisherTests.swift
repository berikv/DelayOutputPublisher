import XCTest
import Combine
import VirtualTimeScheduler
@testable import DelayOutputPublisher

final class DelayOutputPublisherTests: XCTestCase {
    func test_arrayPublisher() throws {
        let scheduler = VirtualTimeScheduler()

        var isCompleted = false
        var receivedAt = [Int]()

        let cancellable = (0..<4).publisher
            .delayOutput(for: .seconds(2), scheduler: scheduler)
            .sink(
                receiveCompletion: { _ in isCompleted = true },
                receiveValue: { value in
                    receivedAt.append(
                        Int(scheduler.now.timeIntervalSinceReferenceTime))
                }
            )

        scheduler.run()

        XCTAssertEqual(receivedAt, [0, 2, 4, 6])
        XCTAssertTrue(isCompleted)

        _ = cancellable // Fix lifetime
    }

    func test_oneValuePerSecond() throws {
        let scheduler = VirtualTimeScheduler()

        var receivedValues = [Int]()
        var receivedTimes = [Int]()

        let subject = PassthroughSubject<Int, Never>()
        let cancellable = subject
            .delayOutput(for: .seconds(1), scheduler: scheduler)
            .sink { value in
                receivedValues.append(value)
                receivedTimes.append(
                    Int(scheduler.now.timeIntervalSinceReferenceTime))
            }

        subject.send(42)
        subject.send(101)
        scheduler.run()

        XCTAssertEqual(receivedValues, [42, 101])
        XCTAssertEqual(receivedTimes, [0, 1])

        receivedValues.removeAll()
        receivedTimes.removeAll()

        subject.send(200)
        subject.send(300)
        scheduler.advanceTime(by: .seconds(1))

        XCTAssertEqual(receivedValues, [200])
        XCTAssertEqual(receivedTimes, [2])

        receivedValues.removeAll()
        receivedTimes.removeAll()

        scheduler.advanceTime(by: .seconds(0))

        XCTAssertEqual(receivedValues, [])
        XCTAssertEqual(receivedTimes, [])

        scheduler.advanceTime(by: .seconds(1))

        XCTAssertEqual(receivedValues, [300])
        XCTAssertEqual(receivedTimes, [3])

        _ = cancellable // Fix lifetime
    }

}
