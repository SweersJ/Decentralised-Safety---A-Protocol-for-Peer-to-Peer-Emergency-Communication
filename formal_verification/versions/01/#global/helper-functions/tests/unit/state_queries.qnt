/// Test pure state-query helpers with explicit values.
///
/// - @returns state_queries_tests the instance-independent state-query unit-test module
module state_queries_tests {
    import unit_fixture.* from "fixture"

    /// Test recognition of empty and populated node states.
    ///
    /// - @returns bool whether the test passes
    run defaultNodeStateFunctionsTest =
        val populatedState: NodeState = {
            ...EMPTY_NODE_STATE,
            messages: Set(message1),
        }

        and {
            isDefaultNodeState(EMPTY_NODE_STATE),
            not(isDefaultNodeState(populatedState)),
        }

    /// Test recognition of absent and present payload values.
    ///
    /// - @returns bool whether the test passes
    run defaultPayloadStateFunctionsTest =
        val payload: Payload = {
            payloadId: 1,
            acks: Set(),
            offers: Set(),
            requests: Set(),
            messages: Set(),
        }

        and {
            isDefaultPayloadState(None),
            not(isDefaultPayloadState(Some(payload))),
        }

    /// Test recognition of default and active payload-exchange states.
    ///
    /// - @returns bool whether the test passes
    run defaultPayloadExchangeStateFunctionsTest =
        val activeState: PayloadExchangeState = {
            ...EMPTY_PAYLOAD_EXCHANGE_STATE,
            phase: MessagesSent,
        }

        and {
            isDefaultPayloadExchangeState(EMPTY_PAYLOAD_EXCHANGE_STATE),
            not(isDefaultPayloadExchangeState(activeState)),
        }

    /// Test extraction of message identifiers from present and absent payloads.
    ///
    /// - @returns bool whether the test passes
    run payloadMessageIdsTest =
        val payload: Payload = {
            payloadId: 1,
            acks: Set(),
            offers: Set(),
            requests: Set(),
            messages: Set(message1, message2),
        }

        and {
            payloadMessageIds(Some(payload)) == Set(message1.messageId, message2.messageId),
            payloadMessageIds(None) == Set(),
        }

    /// Test detection of sent and idle message payload exchange states.
    ///
    /// - @returns bool whether the test passes
    run hasInFlightPayloadTest =
        val sentState: PayloadExchangeState = {
            ...EMPTY_PAYLOAD_EXCHANGE_STATE,
            phase: MessagesSent,
        }

        and {
            hasInFlightMessagesPayload(sentState),
            not(hasInFlightMessagesPayload(EMPTY_PAYLOAD_EXCHANGE_STATE)),
        }
}
