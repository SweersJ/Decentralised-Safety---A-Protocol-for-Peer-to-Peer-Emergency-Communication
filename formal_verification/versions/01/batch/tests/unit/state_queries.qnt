/// Test batch protocol state-query helpers.
///
/// - @returns state_queries_tests the focused unit-test module
module state_queries_tests {
    import unit_fixture.* from "fixture"

    import batch(
        NODES = TEST_NODES,
        RANDOM_MESSAGE_IDS = TEST_MESSAGE_IDS
    ).* from "./../../batch"

    /// Initialise every protocol state variable with deterministic test messages.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithTestMessages() =
        initWithMessageIds(TEST_MESSAGE_IDS)

    // ------------------------------------------------------------------------------------
    // TESTS - HELPER VERIFICATION FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test recognition of default node states for self pairs.
    ///
    /// - @returns bool whether the test passes
    run defaultNodeStateFunctionsTest =
        initWithTestMessages
            .expect(
                and {
                    isDefaultNodeState(getNodeState(nodeState, ALICE, ALICE)),
                    isDefaultNodeState(getNodeState(nodeState, BOB, BOB)),
                    not(isDefaultNodeState(getNodeState(nodeState, ALICE, BOB))),
                    not(isDefaultNodeState(getNodeState(nodeState, BOB, ALICE)))
                }
            )

    /// Test recognition of default payload states.
    ///
    /// - @returns bool whether the test passes
    run defaultPayloadStateFunctionsTest =
        initWithTestMessages
            .expect(
                and {
                    isDefaultPayloadState(getPayload(payloadState, ALICE, ALICE)),
                    isDefaultPayloadState(getPayload(payloadState, ALICE, BOB))
                }
            )

    /// Test recognition of default payload exchange states.
    ///
    /// - @returns bool whether the test passes
    run defaultPayloadExchangeStateFunctionsTest =
        initWithTestMessages
            .expect(
                and {
                    isDefaultPayloadExchangeState(getPayloadExchangeState(payloadExchangeState, ALICE, ALICE)),
                    isDefaultPayloadExchangeState(getPayloadExchangeState(payloadExchangeState, BOB, BOB)),
                    isDefaultPayloadExchangeState(getPayloadExchangeState(payloadExchangeState, ALICE, BOB)),
                    isDefaultPayloadExchangeState(getPayloadExchangeState(payloadExchangeState, BOB, ALICE))
                }
            )

    /// Test extraction of message identifiers from directional payloads.
    ///
    /// - @returns bool whether the test passes
    run payloadMessageIdsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .expect(
                and {
                    payloadMessageIds(getPayload(payloadState, ALICE, BOB))
                        == Set(message1.messageId, message2.messageId),
                    payloadMessageIds(getPayload(payloadState, BOB, ALICE)) == Set()
                }
            )

    /// Test detection of an in-flight directional payload.
    ///
    /// - @returns bool whether the test passes
    run hasInFlightPayloadTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(
                and {
                    hasInFlightMessagesPayload(getPayloadExchangeState(payloadExchangeState, ALICE, BOB)),
                    not(hasInFlightMessagesPayload(getPayloadExchangeState(payloadExchangeState, BOB, ALICE)))
                }
            )
}
