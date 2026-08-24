/// Configure the interactive protocol with two nodes and deterministic initial messages.
///
/// - @returns interactive_two_nodes the deterministic two-node batch protocol module
module interactive_two_nodes {
    // > General
    import basicSpells.* from "./../../../spells/basicSpells"
    // > Types
    import message_id.* from "./../#global/types/message_id"
    import message.* from "./../#global/types/message"
    import payload_id.* from "./../#global/types/payload_id"
    import payload.* from "./../#global/types/payload"
    import node_state.* from "./../#global/types/node_state"
    import node.* from "./../#global/types/node"
    import payload_exchange_phase.* from "./../#global/types/payload_exchange_phase"
    import payload_exchange_state.* from "./../#global/types/payload_exchange_state"
    import record_state.* from "./../#global/types/record_state"
    // > Messages
    import messages.* from "./../#global/messages/messages"
    // > Helper functions
    import getter_helpers.* from "./../#global/helper-functions/getters"
    // > Constant values
    import empty_node_state.* from "./../#global/constant-values/empty_node_state"
    import empty_payload_exchange_state.* from "./../#global/constant-values/empty_payload_exchange_state"
    import two_nodes.* from "./../#global/constant-values/two_nodes"
    // import next_payload_id.* from "./../#global/state-variables/next_payload_id" // only for retransmission

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

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

    import interactive(
        NODES = TWO_NODES,
        RANDOM_MESSAGE_IDS = TWO_NODE_MESSAGE_IDS
    ).* from "interactive"

    // ------------------------------------------------------------------------------------
    // HELPER VERIFICATION ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise two nodes with distinct nonempty message sets that require synchronisation.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithMessagesToSyncTwoNodes() = 
        initWithMessageIds(MESSAGES_TO_SYNC_IDS)

    /// Initialise two nodes such that Bob already contains Alice's selected messages.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithoutMessagesToSyncTwoNodes() =
        initWithMessageIds(MESSAGES_ALREADY_SYNCED_IDS)

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
            .then(addOffers(ALICE, BOB))
            .then(sendOffersPayload(ALICE, BOB))
            .then(receiveOffersPayload(ALICE, BOB))
            .then(determineRequests(ALICE, BOB))
            .then(sendRequestsPayload(ALICE, BOB))
            .then(receiveRequestsPayload(ALICE, BOB))
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
                    getMessagesMessageStore(messageStore, ALICE).size() > 0,
                    getMessagesMessageStore(messageStore, BOB).size() > 0,
                    getMessagesMessageStore(messageStore, ALICE).forall(m => m.in(getMessagesMessageStore(messageStore, BOB))),
                }
            )

    /// Test that an already-synchronised receiver requests no offered messages.
    ///
    /// - @returns bool whether the test passes
    run addMessagesDoesNotFailWhenNoSyncDeltaTest =
        initWithoutMessagesToSyncTwoNodes
            .then(addOffers(ALICE, BOB))
            .then(sendOffersPayload(ALICE, BOB))
            .then(receiveOffersPayload(ALICE, BOB))
            .then(determineRequests(ALICE, BOB))
            .then(sendRequestsPayload(ALICE, BOB))
            .then(receiveRequestsPayload(ALICE, BOB))
            .expect(getPayloadRequests(payloadState, ALICE, BOB).size() == 0)

    /// Test that adding messages produces pending messages and a nonempty payload.
    ///
    /// - @returns bool whether the test passes
    run payloadMessagesWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addOffers(ALICE, BOB))
            .then(sendOffersPayload(ALICE, BOB))
            .then(receiveOffersPayload(ALICE, BOB))
            .then(determineRequests(ALICE, BOB))
            .then(sendRequestsPayload(ALICE, BOB))
            .then(receiveRequestsPayload(ALICE, BOB))
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
            .then(addOffers(ALICE, BOB))
            .then(sendOffersPayload(ALICE, BOB))
            .then(receiveOffersPayload(ALICE, BOB))
            .then(determineRequests(ALICE, BOB))
            .then(sendRequestsPayload(ALICE, BOB))
            .then(receiveRequestsPayload(ALICE, BOB))
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(can_have_in_flight_payload)

    /// Test that acknowledgement determination produces pending acknowledgements.
    ///
    /// - @returns bool whether the test passes
    run pendingAckWitnessTest =
        initWithMessagesToSyncTwoNodes
            .then(addOffers(ALICE, BOB))
            .then(sendOffersPayload(ALICE, BOB))
            .then(receiveOffersPayload(ALICE, BOB))
            .then(determineRequests(ALICE, BOB))
            .then(sendRequestsPayload(ALICE, BOB))
            .then(receiveRequestsPayload(ALICE, BOB))
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
            .then(addOffers(ALICE, BOB))
            .then(sendOffersPayload(ALICE, BOB))
            .then(receiveOffersPayload(ALICE, BOB))
            .then(determineRequests(ALICE, BOB))
            .then(sendRequestsPayload(ALICE, BOB))
            .then(receiveRequestsPayload(ALICE, BOB))
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(
                {
                    val oldBobStore = getMessagesMessageStore(messageStore, BOB)
                    storeReceivedMessages(ALICE, BOB)
                        .expect(
                            oldBobStore.forall(
                                m => m.in(getMessagesMessageStore(messageStore, BOB))
                            )
                        )
                }
            )
}
