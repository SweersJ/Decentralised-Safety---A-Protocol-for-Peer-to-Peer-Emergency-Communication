/// Test batch protocol initialisation, guards, accessors, setters, and helpers.
///
/// - @returns tests_unit the batch protocol unit-test module
module tests_unit {
    import message_id.* from "./../#global/types/message_id"
    import message.* from "./../#global/types/message"
    import payload_id.* from "./../#global/types/payload_id"
    import payload.* from "./../#global/types/payload"
    import node_state.* from "./../#global/types/node_state"
    import node.* from "./../#global/types/node"
    import payload_exchange_phase.* from "./../#global/types/payload_exchange_phase"
    import payload_exchange_state.* from "./../#global/types/payload_exchange_state"
    import messages.* from "./../#global/messages/messages"
    import empty_node_state.* from "./../#global/constant-values/empty_node_state"
    import empty_payload_exchange_state.* from "./../#global/constant-values/empty_payload_exchange_state"
    import guard_helpers.* from "./../#global/helper-functions/guards"
    import getter_helpers.* from "./../#global/helper-functions/getters"
    import state_query_helpers.* from "./../#global/helper-functions/state_queries"
    import basicSpells.* from "./../../../spells/basicSpells"

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    /// Identify Alice in the unit-test protocol instance.
    ///
    /// - @returns Node Alice's node identifier
    pure val ALICE: Node = "Alice"

    /// Identify Bob in the unit-test protocol instance.
    ///
    /// - @returns Node Bob's node identifier
    pure val BOB: Node = "Bob"

    /// Select both participants for the unit-test protocol instance.
    ///
    /// - @returns Set[Node] the unit-test protocol participants
    pure val TEST_NODES: Set[Node] = Set(ALICE, BOB)
    /// Associate each node with deterministic message identifiers for unit tests.
    ///
    /// Fixed input keeps the helper-function tests deterministic.
    ///
    /// - @returns Node -> Set[MessageId] the test message identifiers by node
    pure val TEST_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId, message2.messageId),
        BOB -> Set(message2.messageId)
    )

    import batch(
        NODES = TEST_NODES,
        RANDOM_MESSAGE_IDS = TEST_MESSAGE_IDS
    ).* from "batch"

    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

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

    // ------------------------------------------------------------------------------------
    // TESTS - GUARD FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test that only distinct protocol participants form peer pairs.
    ///
    /// - @returns bool whether the test passes
    run isPeerPairTest =
        initWithTestMessages
            .expect(
                and {
                    isPeerPair(ALICE, BOB),
                    isPeerPair(BOB, ALICE),
                    not(isPeerPair(ALICE, ALICE)),
                    not(isPeerPair(BOB, BOB)),
                }
            )

    /// Test protocol guards in the initial state.
    ///
    /// - @returns bool whether the test passes
    run initialGuardFunctionsTest =
        initWithTestMessages
            .expect(
                and {
                    hasSyncDelta(ALICE, BOB),
                    canAddMessages(ALICE, BOB),
                    canAddMessages(BOB, ALICE), // In this case Alice already has already all the messages of Bob, but that does Bob not know and therefore can also add the messages
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    not(canAckPayload(ALICE, BOB)),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    canIdle(ALICE, BOB),
                }
            )

    /// Test protocol guards after messages are added to a payload.
    ///
    /// - @returns bool whether the test passes
    run messagesAddedGuardFunctionsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    canSendMessagesPayload(ALICE, BOB),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    not(canAckPayload(ALICE, BOB)),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    not(canIdle(ALICE, BOB)),
                }
            )

    /// Test protocol guards after a message payload is received.
    ///
    /// - @returns bool whether the test passes
    run messagesReceivedGuardFunctionsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    canStoreReceivedMessages(ALICE, BOB),
                    canDetermineAck(ALICE, BOB),
                    not(canAckPayload(ALICE, BOB)),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    not(canIdle(ALICE, BOB)),
                }

            )

    /// Test protocol guards after received messages are stored.
    ///
    /// - @returns bool whether the test passes
    run receivedMessagesStoredGuardFunctionsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    canDetermineAck(ALICE, BOB),
                    not(canAckPayload(ALICE, BOB)),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    not(canIdle(ALICE, BOB)),
                }

            )

    /// Test acknowledgement-send guards when acknowledgement determination precedes storage.
    ///
    /// - @returns bool whether the test passes
    run sendAckPayloadGuardFunctionsPath1Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    canAckPayload(ALICE, BOB),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    not(canIdle(ALICE, BOB)),
                }
            )

    /// Test acknowledgement-send guards when storage precedes acknowledgement determination.
    ///
    /// - @returns bool whether the test passes
    run sendAckPayloadGuardFunctionsPath2Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    canAckPayload(ALICE, BOB),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    not(canIdle(ALICE, BOB)),
                }
            )

    /// Test acknowledgement-receive guards when acknowledgement determination precedes storage.
    ///
    /// - @returns bool whether the test passes
    run receiveAckPayloadGuardFunctionsPath1Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    not(canAckPayload(ALICE, BOB)),
                    canReceiveAckPayload(ALICE, BOB),
                    not(canIdle(ALICE, BOB)),
                }
            )

    /// Test acknowledgement-receive guards when storage precedes acknowledgement determination.
    ///
    /// - @returns bool whether the test passes
    run receiveAckPayloadGuardFunctionsPath2Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    not(canAckPayload(ALICE, BOB)),
                    canReceiveAckPayload(ALICE, BOB),
                    not(canIdle(ALICE, BOB)),
                }
            )

    /// Test idle guards after completing the determination-before-storage path.
    ///
    /// - @returns bool whether the test passes
    run idleGuardFunctionsPath1Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    not(canAckPayload(ALICE, BOB)),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    canIdle(ALICE, BOB),
                }
            )

    /// Test idle guards after completing the storage-before-determination path.
    ///
    /// - @returns bool whether the test passes
    run idleGuardFunctionsPath2Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                and {
                    not(canAddMessages(ALICE, BOB)),
                    not(canSendMessagesPayload(ALICE, BOB)),
                    not(canReceiveMessagesPayload(ALICE, BOB)),
                    not(canStoreReceivedMessages(ALICE, BOB)),
                    not(canDetermineAck(ALICE, BOB)),
                    not(canAckPayload(ALICE, BOB)),
                    not(canReceiveAckPayload(ALICE, BOB)),
                    canIdle(ALICE, BOB),
                }
            )

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
                    // state.offers.size() == 0,
                    // state.requests.size() == 0,
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

    // ------------------------------------------------------------------------------------
    // TESTS - SETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test updating one peer pair's payload exchange phase.
    ///
    /// - @returns bool whether the test passes
    run setPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, ALICE, BOB)
                val newPayloadExchangeState = setPayloadExchangeState(
                    ALICE,
                    BOB,
                    MessagesSent,
                    currentPayloadExchangeState.messagesStored,
                    currentPayloadExchangeState.ackDetermined
                )

                and  {
                    newPayloadExchangeState.get(ALICE).get(BOB).phase == MessagesSent,
                    newPayloadExchangeState.get(BOB).get(ALICE).phase == Idle,
                }
            )

    /// Test updating one peer pair's messages-stored flag.
    ///
    /// - @returns bool whether the test passes
    run setPayloadExchangeStateMessagesStoredTest =
        initWithTestMessages
            .expect(
                val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, ALICE, BOB)
                val newPayloadExchangeState = setPayloadExchangeState(
                    ALICE,
                    BOB,
                    MessagesSent,
                    true,
                    currentPayloadExchangeState.ackDetermined
                )

                and {
                    newPayloadExchangeState.get(ALICE).get(BOB).messagesStored,
                    not(newPayloadExchangeState.get(BOB).get(ALICE).messagesStored),
                }
            )


    /// Test updating one peer pair's acknowledgement-determined flag.
    ///
    /// - @returns bool whether the test passes
    run setPayloadExchangeStateAckDeterminedTest =
        initWithTestMessages
            .expect(
                val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, ALICE, BOB)
                val newPayloadExchangeState = setPayloadExchangeState(
                    ALICE,
                    BOB,
                    MessagesSent,
                    currentPayloadExchangeState.messagesStored,
                    true
                )

                and {
                    newPayloadExchangeState.get(ALICE).get(BOB).ackDetermined,
                    not(newPayloadExchangeState.get(BOB).get(ALICE).ackDetermined),
                }
            )


    // ------------------------------------------------------------------------------------
    // TESTS - GENERAL FUNCTIONS
    // ------------------------------------------------------------------------------------

    // Insert general function tests

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
    run defaultPayloadExchangeStateFunctionsText =
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
