import Foundation
import Combine

extension Publisher {
    public func delayOutput<S>(
        for interval: S.SchedulerTimeType.Stride,
        tolerance: S.SchedulerTimeType.Stride? = nil,
        scheduler: S,
        options: S.SchedulerOptions? = nil
    ) -> DelayOutputPublisher<Self, S>
    where S : Scheduler
    {
        DelayOutputPublisher(
            upstream: self,
            interval: interval,
            tolerance: tolerance,
            scheduler: scheduler,
            options: options)
    }
}

public struct DelayOutputPublisher<Upstream, S>: Publisher
where Upstream: Publisher, S: Scheduler {

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    let upstream: Upstream
    let interval: S.SchedulerTimeType.Stride
    let tolerance: S.SchedulerTimeType.Stride?
    let scheduler: S
    let options: S.SchedulerOptions?

    public init(
        upstream: Upstream,
        interval: S.SchedulerTimeType.Stride,
        tolerance: S.SchedulerTimeType.Stride? = nil,
        scheduler: S,
        options: S.SchedulerOptions? = nil
    ) {
        self.upstream = upstream
        self.interval = interval
        self.tolerance = tolerance
        self.scheduler = scheduler
        self.options = options
    }

    public func receive<S: Subscriber>(subscriber: S)
    where S.Input == Upstream.Output,
          S.Failure == Failure
    {
        let subscription = Subscription(
            subscriber: subscriber,
            interval: interval,
            tolerance: tolerance,
            scheduler: scheduler,
            options: options)

        subscriber.receive(subscription: subscription)
        upstream.receive(subscriber: subscription)
    }
}

extension DelayOutputPublisher {
    final class Subscription<Downstream, S>
    where Downstream: Subscriber,
          Downstream.Input == Output,
          Downstream.Failure == Failure,
          S: Scheduler
    {
        private var subscriber: Downstream?
        let interval: S.SchedulerTimeType.Stride
        let tolerance: S.SchedulerTimeType.Stride?
        let scheduler: S
        let options: S.SchedulerOptions?

        private var demand: Subscribers.Demand = .none
        private var outputQueue = Queue<Output>()
        private var lastOutput: S.SchedulerTimeType
        private var isScheduled = false
        private var completion: Subscribers.Completion<Downstream.Failure>?

        init(
            subscriber: Downstream,
            interval: S.SchedulerTimeType.Stride,
            tolerance: S.SchedulerTimeType.Stride? = nil,
            scheduler: S,
            options: S.SchedulerOptions? = nil
        ) {
            self.subscriber = subscriber
            self.interval = interval
            self.tolerance = tolerance
            self.scheduler = scheduler
            self.options = options

            // Distant past
            lastOutput = scheduler.now
                .advanced(by: .seconds(-.greatestFiniteMagnitude))
        }
    }
}

extension DelayOutputPublisher.Subscription: Subscriber {
    func receive(subscription: Subscription) {
        subscription.request(demand)
    }

    func receive(_ input: Downstream.Input) -> Subscribers.Demand {
        guard subscriber != nil else { return .none }

        outputQueue.enqueue(input)

        if !isScheduled {
            scheduleOutput()
        }

        return demand
    }

    func receive(completion: Subscribers.Completion<Downstream.Failure>) {
        if !isScheduled {
            subscriber?.receive(completion: completion)
        } else {
            self.completion = completion
        }
    }

    private func scheduleOutput() {
        guard let output = outputQueue.dequeue() else {
            isScheduled = false
            if let completion = completion {
                subscriber?.receive(completion: completion)
            }
            return
        }

        isScheduled = true

        let scheduleTime = lastOutput.advanced(by: interval)

        scheduler.schedule(after: scheduleTime) { [self] in
            guard let subscriber = subscriber else {
                isScheduled = false
                return
            }

            demand = subscriber.receive(output)
            lastOutput = scheduler.now

            scheduleOutput()
        }
    }
}

extension DelayOutputPublisher.Subscription: Cancellable {
    func cancel() {
        subscriber = nil
    }
}

extension DelayOutputPublisher.Subscription: Subscription {
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
    }
}


// From https://github.com/raywenderlich/swift-algorithm-club/tree/master/Queue
private struct Queue<T> {
  fileprivate var array = [T?]()
  fileprivate var head = 0

  public var isEmpty: Bool {
    return count == 0
  }

  public var count: Int {
    return array.count - head
  }

  public mutating func enqueue(_ element: T) {
    array.append(element)
  }

  public mutating func dequeue() -> T? {
    guard head < array.count, let element = array[head] else { return nil }

    array[head] = nil
    head += 1

    let percentage = Double(head)/Double(array.count)
    if array.count > 50 && percentage > 0.25 {
      array.removeFirst(head)
      head = 0
    }

    return element
  }

  public var front: T? {
    if isEmpty {
      return nil
    } else {
      return array[head]
    }
  }
}
