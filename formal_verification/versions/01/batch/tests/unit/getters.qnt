/// Test pure getters over batch protocol state.
///
/// - @returns getters_tests the focused unit-test module
module getters_tests {
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
    // TESTS - GETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test retrieval of the node state for a peer pair.
    ///
    /// - @returns bool whether the test passes
    run getNodeStateTest =
        initWithTestMessages
            .expect(
                val state = getNodeState(nodeState, ALICE, BOB)

                and {
                    state.offers.size() == 0,
                    state.requests.size() == 0,
                    state.messages.size() == 2,
                }

            )

    /// Test that an initial sender-receiver pair has no payload.
    ///
    /// - @returns bool whether the test passes
    run getPayloadTest =
        initWithTestMessages
            .expect(getPayload(payloadState, ALICE, BOB) == None)

    /// Test retrieval of an initial payload exchange state.
    ///
    /// - @returns bool whether the test passes
    run getPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                val state = getPayloadExchangeState(payloadExchangeState, ALICE, BOB)

                and {
                    state.phase == Idle,
                    not(state.messagesStored),
                    not(state.ackDetermined),
                }
            )
}
