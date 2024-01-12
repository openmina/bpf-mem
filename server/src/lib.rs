// Copyright (c) Viable Systems
// SPDX-License-Identifier: MIT

#![forbid(unsafe_code)]

mod memory_map;

mod state;
pub use self::state::{AtomicState, Reporter as StateReporter};

mod history;
pub use self::history::{
    Page, History, AllocationState, FrameReport, EventLast, Tracker, Reporter, PageHistory,
};

mod stack;
pub use self::stack::StackResolver;

mod table;

pub mod server;

mod collector;
pub use self::collector::{Consumer, Aggregator, RawEvent};
