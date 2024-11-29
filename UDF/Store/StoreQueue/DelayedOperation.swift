//===--- DelayedOperation.swift --------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

final class DelayedOperation: AsynchronousOperation {
    var priority: StoreOperation.Priority
    private let delay: TimeInterval
    var task: Task<Void, Never>? = nil

    init(delay: TimeInterval, priority: StoreOperation.Priority) {
        self.delay = delay
        self.priority = priority
        super.init()
    }

    override func main() {
        self.task = Task.detached(priority: priority.taskPriority) { [weak self] in
            let delay = self?.delay ?? 0
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self?.finish()
        }
    }

    override func finish() {
        self.task = nil
        super.finish()
    }

    override func cancel() {
        self.task?.cancel()
        self.task = nil
        super.cancel()
    }
}
