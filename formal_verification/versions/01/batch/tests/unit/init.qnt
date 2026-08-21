/// Test batch protocol initialization helpers.
///
/// - @returns init_tests the focused unit-test module
module init_tests {
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
    // TESTS - INIT FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test node-state initialisation for peer and self pairs.
    ///
    /// - @returns bool whether the test passes
    run initNodeStateTest =
        initWithTestMessages
            .expect(
                and {
                    getNodeState(nodeState, ALICE, BOB).messages == Set(message1, message2),
                    getNodeState(nodeState, BOB, ALICE).messages == Set(message2),
                    getNodeState(nodeState, ALICE, ALICE) == EMPTY_NODE_STATE,
                    getNodeState(nodeState, BOB, BOB) == EMPTY_NODE_STATE,
                }
            )

    /// Test that every payload state is initially empty.
    ///
    /// - @returns bool whether the test passes
    run initPayloadStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    getPayload(payloadState, sender, receiver) == None
                ))
            )

    /// Test message-store initialisation from deterministic identifiers.
    ///
    /// - @returns bool whether the test passes
    run initMessageStoreTest =
        initWithTestMessages
            .expect(
                and {
                    getMessagesMessageStore(messageStore, ALICE) == Set(message1, message2),
                    getMessagesMessageStore(messageStore, BOB) == Set(message2),
                }
            )

    /// Test that every payload exchange state is initially empty.
    ///
    /// - @returns bool whether the test passes
    run initPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    getPayloadExchangeState(payloadExchangeState, sender, receiver)
                        == EMPTY_PAYLOAD_EXCHANGE_STATE
                ))
            )

    /// Test that injected initial identifiers cover each node and reference known messages.
    ///
    /// - @returns bool whether the test passes
    run configuredMessageIdsTest =
        initWithTestMessages
            .expect(
                and {
                    RANDOM_MESSAGE_IDS.keys() == NODES,
                    NODES.forall(node =>
                        RANDOM_MESSAGE_IDS.get(node).forall(
                            id => id.in(MESSAGES.keys())
                        )
                    ),
                }
            )
}
