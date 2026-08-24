/// Test the shared safety predicates with valid states and targeted counterexamples.
///
/// - @returns safety_predicates_tests the focused safety-predicate unit-test module
module safety_predicates_tests {
    import unit_fixture.* from "./../../../helper-functions/tests/unit/fixture"
    import record_state.* from "./../../../types/record_state"
    import record_type.* from "./../../../types/record_type"
    import reverse_payloadState_is_always_empty_safety.* from "./../../reverse_payloadState_is_always_empty"
    import self_nodeState_is_always_empty_safety.* from "./../../self_nodeState_is_always_empty"
    import self_payloadExchangeState_is_always_empty_safety.* from "./../../self_payloadExchangeState_is_always_empty"
    import self_payloadState_is_always_empty_safety.* from "./../../self_payloadState_is_always_empty"

    /// Check that self-directed node state must have no messages, offers, or requests.
    ///
    /// - @returns bool whether the test passes
    run selfNodeStateIsAlwaysEmptyPredicateTest =
        val emptyStates: Node -> (Node -> NodeState) = Map(
            ALICE -> Map(ALICE -> EMPTY_NODE_STATE, BOB -> EMPTY_NODE_STATE),
            BOB -> Map(ALICE -> EMPTY_NODE_STATE, BOB -> EMPTY_NODE_STATE)
        )
        val offer: RecordState = { messageId: message1.messageId, recordType: OfferRecord }
        val request: RecordState = { messageId: message1.messageId, recordType: RequestRecord }
        val selfMessageStates = emptyStates.setBy(ALICE, states => states.setBy(
            ALICE, _ => { ...EMPTY_NODE_STATE, messages: Set(message1) }
        ))
        val selfOfferStates = emptyStates.setBy(ALICE, states => states.setBy(
            ALICE, _ => { ...EMPTY_NODE_STATE, offers: Set(offer) }
        ))
        val selfRequestStates = emptyStates.setBy(ALICE, states => states.setBy(
            ALICE, _ => { ...EMPTY_NODE_STATE, requests: Set(request) }
        ))

        and {
            self_nodeState_is_always_empty_predicate(TEST_NODES, emptyStates),
            not(self_nodeState_is_always_empty_predicate(TEST_NODES, selfMessageStates)),
            not(self_nodeState_is_always_empty_predicate(TEST_NODES, selfOfferStates)),
            not(self_nodeState_is_always_empty_predicate(TEST_NODES, selfRequestStates)),
        }

    /// Check that self-directed payload values must remain absent.
    ///
    /// - @returns bool whether the test passes
    run selfPayloadStateIsAlwaysEmptyPredicateTest =
        val emptyPayloads: Node -> (Node -> Option[Payload]) = Map(
            ALICE -> Map(ALICE -> None, BOB -> None),
            BOB -> Map(ALICE -> None, BOB -> None)
        )
        val payload: Payload = {
            payloadId: 1,
            acks: Set(),
            offers: Set(),
            requests: Set(),
            messages: Set(message1),
        }
        val selfPayloads = emptyPayloads.setBy(ALICE, payloads => payloads.setBy(
            ALICE, _ => Some(payload)
        ))

        and {
            self_payloadState_is_always_empty_predicate(TEST_NODES, emptyPayloads),
            not(self_payloadState_is_always_empty_predicate(TEST_NODES, selfPayloads)),
        }

    /// Check that self-directed exchange state must remain idle and unprocessed.
    ///
    /// - @returns bool whether the test passes
    run selfPayloadExchangeStateIsAlwaysEmptyPredicateTest =
        val emptyExchangeStates: Node -> (Node -> PayloadExchangeState) = Map(
            ALICE -> Map(ALICE -> EMPTY_PAYLOAD_EXCHANGE_STATE, BOB -> EMPTY_PAYLOAD_EXCHANGE_STATE),
            BOB -> Map(ALICE -> EMPTY_PAYLOAD_EXCHANGE_STATE, BOB -> EMPTY_PAYLOAD_EXCHANGE_STATE)
        )
        val activeSelfStates = emptyExchangeStates.setBy(ALICE, states => states.setBy(
            ALICE, _ => { ...EMPTY_PAYLOAD_EXCHANGE_STATE, phase: MessagesSent }
        ))
        val storedSelfStates = emptyExchangeStates.setBy(ALICE, states => states.setBy(
            ALICE, _ => { ...EMPTY_PAYLOAD_EXCHANGE_STATE, messagesStored: true }
        ))
        val determinedSelfStates = emptyExchangeStates.setBy(ALICE, states => states.setBy(
            ALICE, _ => { ...EMPTY_PAYLOAD_EXCHANGE_STATE, ackDetermined: true }
        ))

        and {
            self_payloadExchangeState_is_always_empty_predicate(TEST_NODES, emptyExchangeStates),
            not(self_payloadExchangeState_is_always_empty_predicate(TEST_NODES, activeSelfStates)),
            not(self_payloadExchangeState_is_always_empty_predicate(TEST_NODES, storedSelfStates)),
            not(self_payloadExchangeState_is_always_empty_predicate(TEST_NODES, determinedSelfStates)),
        }

    /// Check that each active peer-exchange direction has its corresponding payload.
    ///
    /// - @returns bool whether the test passes
    run reversePayloadStateIsAlwaysEmptyPredicateTest =
        val emptyPayloads: Node -> (Node -> Option[Payload]) = Map(
            ALICE -> Map(ALICE -> None, BOB -> None),
            BOB -> Map(ALICE -> None, BOB -> None)
        )
        val idleExchangeStates: Node -> (Node -> PayloadExchangeState) = Map(
            ALICE -> Map(ALICE -> EMPTY_PAYLOAD_EXCHANGE_STATE, BOB -> EMPTY_PAYLOAD_EXCHANGE_STATE),
            BOB -> Map(ALICE -> EMPTY_PAYLOAD_EXCHANGE_STATE, BOB -> EMPTY_PAYLOAD_EXCHANGE_STATE)
        )
        val activeExchangeStates = idleExchangeStates.setBy(ALICE, states => states.setBy(
            BOB, _ => { ...EMPTY_PAYLOAD_EXCHANGE_STATE, phase: MessagesSent }
        ))
        val payload: Payload = {
            payloadId: 1,
            acks: Set(),
            offers: Set(),
            requests: Set(),
            messages: Set(message1),
        }
        val forwardPayloads = emptyPayloads.setBy(ALICE, payloads => payloads.setBy(
            BOB, _ => Some(payload)
        ))
        val reversePayloads = emptyPayloads.setBy(BOB, payloads => payloads.setBy(
            ALICE, _ => Some(payload)
        ))
        val reverseActiveExchangeStates = idleExchangeStates.setBy(BOB, states => states.setBy(
            ALICE, _ => { ...EMPTY_PAYLOAD_EXCHANGE_STATE, phase: MessagesSent }
        ))
        val concurrentExchangeStates = activeExchangeStates.setBy(BOB, states => states.setBy(
            ALICE, _ => { ...EMPTY_PAYLOAD_EXCHANGE_STATE, phase: MessagesSent }
        ))
        val concurrentPayloads = forwardPayloads.setBy(BOB, payloads => payloads.setBy(
            ALICE, _ => Some(payload)
        ))

        and {
            reverse_payloadState_is_always_empty_predicate(TEST_NODES, emptyPayloads, idleExchangeStates),
            not(reverse_payloadState_is_always_empty_predicate(TEST_NODES, emptyPayloads, activeExchangeStates)),
            reverse_payloadState_is_always_empty_predicate(TEST_NODES, forwardPayloads, activeExchangeStates),
            not(reverse_payloadState_is_always_empty_predicate(TEST_NODES, reversePayloads, activeExchangeStates)),
            reverse_payloadState_is_always_empty_predicate(TEST_NODES, reversePayloads, reverseActiveExchangeStates),
            reverse_payloadState_is_always_empty_predicate(TEST_NODES, concurrentPayloads, concurrentExchangeStates),
        }
}
