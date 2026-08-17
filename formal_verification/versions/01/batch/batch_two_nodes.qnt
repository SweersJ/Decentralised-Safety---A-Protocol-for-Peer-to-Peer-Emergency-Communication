/// Configure the batch protocol with two nodes and deterministic initial messages.
///
/// - @returns batch_two_nodes the deterministic two-node batch protocol module
module batch_two_nodes {
    import message_id.* from "./../types/message_id"
    import message.* from "./../types/message"
    import payload_id.* from "./../types/payload_id"
    import payload.* from "./../types/payload"
    import node_state.* from "./../types/node_state"
    import node.* from "./../types/node"
    import payload_exchange_phase.* from "./../types/payload_exchange_phase"
    import payload_exchange_state.* from "./../types/payload_exchange_state"
    import messages.* from "./../messages/messages"
    import basicSpells.* from "./../../../spells/basicSpells"

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    /// Identify Alice in this concrete protocol instance.
    ///
    /// - @returns Node Alice's node identifier
    pure val ALICE: Node = "Alice"

    /// Identify Bob in this concrete protocol instance.
    ///
    /// - @returns Node Bob's node identifier
    pure val BOB: Node = "Bob"

    /// Select the two nodes participating in this protocol instance.
    ///
    /// - @returns Set[Node] the configured protocol participants
    pure val TWO_NODES: Set[Node] = Set(ALICE, BOB)

    /// Select the messages initially stored by Alice.
    ///
    /// - @returns Set[MessageId] Alice's deterministic initial message identifiers
    pure val ALICE_MESSAGE_IDS: Set[MessageId] = Set(
        message1.messageId,
        message2.messageId
    )

    /// Select the messages initially stored by Bob.
    ///
    /// - @returns Set[MessageId] Bob's deterministic initial message identifiers
    pure val BOB_MESSAGE_IDS: Set[MessageId] = Set(
        message3.messageId
    )

    /// Assign the configured initial messages to both protocol nodes.
    ///
    /// - @returns Node -> Set[MessageId] the deterministic message identifiers indexed by node
    pure val TWO_NODE_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> ALICE_MESSAGE_IDS,
        BOB -> BOB_MESSAGE_IDS
    )
    /// Assign distinct messages to Alice and Bob so synchronisation is required.
    ///
    /// - @returns Node -> Set[MessageId] the fixed message identifiers for the synchronisation scenario
    pure val MESSAGES_TO_SYNC_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId),
        BOB -> Set(message2.messageId)
    )

    /// Assign Alice's messages as a subset of Bob's so no synchronisation delta exists.
    ///
    /// - @returns Node -> Set[MessageId] the fixed message identifiers for the already-synchronised scenario
    pure val MESSAGES_ALREADY_SYNCED_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId),
        BOB -> Set(message1.messageId, message2.messageId)
    )

    // ------------------------------------------------------------------------------------
    // PROTOCOL INSTANCE
    // ------------------------------------------------------------------------------------

    import batch(
        NODES = TWO_NODES,
        RANDOM_MESSAGE_IDS = TWO_NODE_MESSAGE_IDS
    ).* from "batch"

    // ------------------------------------------------------------------------------------
    // INIT AND STEP ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise the configured batch protocol instance.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initTwoNodes() = init

    /// Advance the configured batch protocol instance by one transition.
    ///
    /// - @returns bool whether an enabled protocol transition is performed
    action stepTwoNodes() = step

    // ------------------------------------------------------------------------------------
    // HELPER VERIFICATION ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise two nodes with distinct nonempty message sets that require synchronisation.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithMessagesToSyncTwoNodes() = all {
        nodeState' = initNodeState(MESSAGES_TO_SYNC_IDS),
        payloadState' = initPayloadState,
        messageStore' = initMessageStore(MESSAGES_TO_SYNC_IDS),
        payloadExchangeState' = initPayloadExchangeState,
    }

    /// Initialise two nodes such that Bob already contains Alice's selected messages.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithoutMessagesToSyncTwoNodes() = all {
        nodeState' = initNodeState(MESSAGES_ALREADY_SYNCED_IDS),
        payloadState' = initPayloadState,
        messageStore' = initMessageStore(MESSAGES_ALREADY_SYNCED_IDS),
        payloadExchangeState' = initPayloadExchangeState,
    }

    // -------------------------------------------------------------------------------------

    // SAFETY PROPOSITIONS
    // -------------------------------------------------------------------------------------

    /// Assert that the model contains exactly Alice and Bob.
    ///
    /// - @returns bool whether the proposition holds
    val two_nodes_only =
        NODES.size() == 2

    // ------------------------------------------------------------------------------------

    // TESTS
    // ------------------------------------------------------------------------------------

    /// Test that a complete exchange synchronises Alice's messages to Bob.
    ///
    /// - @returns bool whether the test passes
    run messageStoreSyncTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                // After complete bidirectional message exchange, both nodes should have messages
                // This verifies that the protocol correctly syncs messages when nodes start with different sets
                and {
                    messageStore.get(ALICE).size() > 0,
                    messageStore.get(BOB).size() > 0,
                    messageStore.get(ALICE).forall(m => m.in(messageStore.get(BOB))),
                }
            )

    /// Test that adding messages remains enabled when no synchronisation delta exists.
    ///
    /// Unknown receiver knowledge permits redundant transmission, so Alice can still send
    /// messages to Bob when Bob already has all of them.
    ///
    /// - @returns bool whether the test passes
    run addMessagesDoesNotFailWhenNoSyncDeltaTest =
        initWithoutMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))

    /// Test that adding messages produces pending messages and a nonempty payload.
    ///
    /// - @returns bool whether the test passes
    run payloadMessagesWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .expect(
                and {
                    can_have_pending_messages,
                    can_have_payload_messages,
                }
            )

    /// Test that sending a message payload produces an in-flight payload.
    ///
    /// - @returns bool whether the test passes
    run inFlightPayloadWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(can_have_in_flight_payload)

    /// Test that acknowledgement determination produces pending acknowledgements.
    ///
    /// - @returns bool whether the test passes
    run pendingAckWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .expect(
                and {
                    can_have_pending_acks,
                    can_have_delivered_payload,
                }
            )

    /// Test that storing received messages preserves every message already stored.
    ///
    /// - @returns bool whether the test passes
    run storeReceivedMessagesPreservesExistingMessagesTest =
        initWithMessagesToSyncTwoNodes
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(
                {
                    val oldBobStore = messageStore.get(BOB)
                    storeReceivedMessages(ALICE, BOB)
                        .expect(
                            oldBobStore.forall(
                                m => m.in(messageStore.get(BOB))
                            )
                        )
                }
            )
}
