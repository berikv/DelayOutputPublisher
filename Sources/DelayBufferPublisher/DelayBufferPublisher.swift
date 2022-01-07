import Foundation
import Combine

public struct DelayBufferPublisher {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}

extension Publisher {
    func delayBuffer() -> RateLimitingPublisher<Self> {
        RateLimitingPublisher(self)
    }
}

let delay: TimeInterval = 3
public struct RateLimitingPublisher<Upstream>: Publisher
where Upstream: Publisher {

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    public let upstream: Upstream

    public init(_ upstream: Upstream) {
        self.upstream = upstream
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Upstream.Output, S.Failure == Failure {
        let subscription = _Subscription(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
        upstream.receive(subscriber: subscription)
    }
}

extension RateLimitingPublisher {
    final class _Subscription<Downstream>
    where Downstream: Subscriber,
          Downstream.Input == Output,
          Downstream.Failure == Failure
    {
        private var subscriber: Downstream?
        private var demand: Subscribers.Demand = .none
        private var buffer = [Output]()
        private var lastOutput: Date = .distantPast

        init(subscriber: Downstream) {
            self.subscriber = subscriber
        }
    }
}

extension RateLimitingPublisher._Subscription: Subscriber {
    func receive(subscription: Subscription) {
        subscription.request(demand)
    }

    func receive(_ input: Downstream.Input) -> Subscribers.Demand {
//        if buffer.isEmpty, let subscriber = subscriber {
//            demand = subscriber.receive(input)
//            return demand
//        }

        buffer.append(input)

        guard let subscriber = subscriber else { return .none }

        while let output = buffer.first {
            if -lastOutput.timeIntervalSinceNow > delay {
                buffer = Array(buffer.dropFirst())
                demand = subscriber.receive(output)
                lastOutput = Date()
            } else {
                scheduleBufferClearing()
            }
        }

        return demand
    }

    func receive(completion: Subscribers.Completion<Downstream.Failure>) {
        subscriber?.receive(completion: completion)
    }

    private func scheduleBufferClearing() {
        let deadline = DispatchTime.now() + delay + lastOutput.timeIntervalSinceNow
        DispatchQueue.main.asyncAfter(deadline: deadline) { [self] in
            guard let subscriber = subscriber else { return }
            guard let output = buffer.first else { return }
            buffer = Array(buffer.dropFirst())
            demand = subscriber.receive(output)
            lastOutput = Date()
            scheduleBufferClearing()
        }
    }
}


extension RateLimitingPublisher._Subscription: Cancellable {
    func cancel() {
        subscriber = nil
    }
}

extension RateLimitingPublisher._Subscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
        while let subscriber = subscriber, let value = buffer.first {
            self.demand = subscriber.receive(value)
        }
    }
}

