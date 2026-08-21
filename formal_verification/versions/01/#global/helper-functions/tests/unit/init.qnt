/// Test configured global initialization helpers directly.
///
/// - @returns init_tests the instance-independent initialization unit-test module
module init_tests {
    import unit_fixture.* from "fixture"
    import init_helpers(INIT_NODES = TEST_NODES).* from "./../../init"

    /// Test node-state initialization for peer and self pairs.
    ///
    /// - @returns bool whether the test passes
    run initNodeStateTest =
        val state = initNodeState(TEST_MESSAGE_IDS)

        and {
            getNodeState(state, ALICE, BOB).messages == Set(message1, message2),
            getNodeState(state, BOB, ALICE).messages == Set(message2),
            getNodeState(state, ALICE, ALICE) == EMPTY_NODE_STATE,
            getNodeState(state, BOB, BOB) == EMPTY_NODE_STATE,
        }

    /// Test that initialization creates an absent payload for every node pair.
    ///
    /// - @returns bool whether the test passes
    run initPayloadStateTest =
        val state = initPayloadState

        TEST_NODES.forall(sender => TEST_NODES.forall(receiver =>
            getPayload(state, sender, receiver) == None
        ))

    /// Test message-store initialization from deterministic identifiers.
    ///
    /// - @returns bool whether the test passes
    run initMessageStoreTest =
        val store = initMessageStore(TEST_MESSAGE_IDS)

        and {
            getMessagesMessageStore(store, ALICE) == Set(message1, message2),
            getMessagesMessageStore(store, BOB) == Set(message2),
        }

    /// Test that initialization creates an empty exchange state for every node pair.
    ///
    /// - @returns bool whether the test passes
    run initPayloadExchangeStateTest =
        val state = initPayloadExchangeState

        TEST_NODES.forall(sender => TEST_NODES.forall(receiver =>
            getPayloadExchangeState(state, sender, receiver)
                == EMPTY_PAYLOAD_EXCHANGE_STATE
        ))

    /// Test that generated identifiers cover every configured node and known message.
    ///
    /// - @returns bool whether the test passes
    run initRandomMessageIdsTest =
        val messageIds = initRandomMessageIds

        and {
            messageIds.keys() == TEST_NODES,
            TEST_NODES.forall(node =>
                messageIds.get(node).forall(id => id.in(MESSAGES.keys()))
            ),
        }
}
