# Changelog

## 1.0.0

Core statechart functionality.

## 1.0.1

Fixed a minor bug.

## 1.0.1+1

Added documentation. (Finally)

## 1.0.1+2

Added test coverage tooling.

## 1.1.0

1. Removed need for futures and the Resolver class when constructing statecharts and executing events.
2. Ported algorithm from the [SCXML spec](https://www.w3.org/TR/scxml/) to deal correctly with history states.

### SCXML not yet fully implemented

1. The engine needs to maintain a queue of events and to implement hierarchical events.
2. Need to implement data manipulation via datamodels.

## 1.1.1

Adds `depth` to State for use with layout algorithms.

## 1.1.2

Adds `description` to State and Transition for documenting statecharts in-place.



