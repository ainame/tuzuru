import Foundation

/// Actor-wrapped iterator for thread-safe consumption across multiple concurrent tasks
///
/// This enables a worker pool pattern where multiple tasks can safely pull items
/// from a shared iterator, similar to Ruby's Queue/Thread pattern.
///
/// Example:
/// ```swift
/// let items = [1, 2, 3, 4, 5]
/// let iterator = SharedIterator(items.makeIterator())
///
/// await withThrowingTaskGroup(of: Int.self) { group in
///     for _ in 0..<3 {  // 3 workers
///         group.addTask {
///             while let item = await iterator.next() {
///                 // Process item
///             }
///         }
///     }
/// }
/// ```
actor SharedIterator<Base: IteratorProtocol> where Base.Element: Sendable {
    private var base: Base

    init(_ base: Base) {
        self.base = base
    }

    /// Returns the next element in the iteration, or nil if exhausted
    ///
    /// This method is thread-safe and can be called concurrently from multiple tasks.
    /// Each element is yielded to exactly one caller (work-stealing behavior).
    func next() -> Base.Element? {
        base.next()
    }
}
