/// Test batch protocol initialisation, guards, accessors, setters, and helpers.
///
/// - @returns tests_unit the batch protocol unit-test module
module tests_unit {
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

    // -------------------------------------------------------------------------------------
    // HELPER VERIFICATION FUNCTIONS
    // -------------------------------------------------------------------------------------

    /// Check whether a pair's node state equals the empty default state.
    ///
    /// - @param Node sender the node maintaining the state
    /// - @param Node receiver the peer represented by the state
    /// - @returns bool the computed result
    def isDefaultNodeState(sender: Node, receiver: Node): bool = {
        val nodeState = getNodeState(sender, receiver)
        and {
            nodeState.messages.size() == 0,
            // nodeState.offers.size() == 0,  //only for interactive
            // nodeState.requests.size() == 0, //only for interactive
        }
    }

    /// Check whether a sender-receiver pair has no payload.
    ///
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns bool whether the payload is absent
    def isDefaultPayloadState(sender: Node, receiver: Node): bool = {
        getPayload(sender, receiver) == None
    }

    /// Check whether a pair's exchange state equals the empty default exchange state.
    ///
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns bool the computed result
    def isDefaultPayloadExchangeState(sender: Node, receiver: Node): bool = {
        val payloadExchangeState = getPayloadExchangeState(sender, receiver)

        and {
            payloadExchangeState.phase == Idle,
            not(payloadExchangeState.messagesStored),
            not(payloadExchangeState.ackDetermined),
        }
    }

    /// Return the identifiers of all messages in a pair's payload.
    ///
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns Set[MessageId] the computed result
    def payloadMessageIds(sender: Node, receiver: Node): Set[MessageId] = {
        getSetMessageIds(getPayloadMessages(sender, receiver))
    }

    /// Check whether a pair currently has a sent message payload awaiting receipt.
    ///
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns bool the computed result
    def hasInFlightPayload(sender: Node, receiver: Node): bool = {
        getPayloadExchangeState(sender, receiver).phase == MessagesSent
    }

    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise every protocol state variable with deterministic test messages.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithTestMessages() = all {
        nodeState' = initNodeState(TEST_MESSAGE_IDS),
        payloadState' = initPayloadState,
        messageStore' = initMessageStore(TEST_MESSAGE_IDS),
        payloadExchangeState' = initPayloadExchangeState,
    }

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
                    nodeState.get(ALICE).get(BOB).messages == Set(message1, message2),
                    nodeState.get(BOB).get(ALICE).messages == Set(message2),
                    nodeState.get(ALICE).get(ALICE) == EMPTY_NODE_STATE,
                    nodeState.get(BOB).get(BOB) == EMPTY_NODE_STATE,
                }
            )

    /// Test that every payload state is initially empty.
    ///
    /// - @returns bool whether the test passes
    run initPayloadStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    payloadState.get(sender).get(receiver) == None
                ))
            )

    /// Test message-store initialisation from deterministic identifiers.
    ///
    /// - @returns bool whether the test passes
    run initMessageStoreTest =
        initWithTestMessages
            .expect(
                and {
                    messageStore.get(ALICE) == Set(message1, message2),
                    messageStore.get(BOB) == Set(message2),
                }
            )

    /// Test that every payload exchange state is initially empty.
    ///
    /// - @returns bool whether the test passes
    run initPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    payloadExchangeState.get(sender).get(receiver)
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
                val state = getNodeState(ALICE, BOB)

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
            .expect(getPayload(ALICE, BOB) == None)

    /// Test retrieval of an initial payload exchange state.
    ///
    /// - @returns bool whether the test passes
    run getPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                val state = getPayloadExchangeState(ALICE, BOB)

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
                val currentPayloadExchangeState = payloadExchangeState.get(ALICE).get(BOB)
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
                val currentPayloadExchangeState = payloadExchangeState.get(ALICE).get(BOB)
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
                val currentPayloadExchangeState = payloadExchangeState.get(ALICE).get(BOB)
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
                    isDefaultNodeState(ALICE, ALICE),
                    isDefaultNodeState(BOB, BOB),
                    not(isDefaultNodeState(ALICE, BOB)),
                    not(isDefaultNodeState(BOB, ALICE))
                }
            )

    /// Test recognition of default payload states.
    ///
    /// - @returns bool whether the test passes
    run defaultPayloadStateFunctionsTest =
        initWithTestMessages
            .expect(
                and {
                    isDefaultPayloadState(ALICE, ALICE),
                    isDefaultPayloadState(ALICE, BOB)
                }
            )

    /// Test recognition of default payload exchange states.
    ///
    /// - @returns bool whether the test passes
    run defaultPayloadExchangeStateFunctionsText =
        initWithTestMessages
            .expect(
                and {
                    isDefaultPayloadExchangeState(ALICE, ALICE),
                    isDefaultPayloadExchangeState(BOB, BOB),
                    isDefaultPayloadExchangeState(ALICE, BOB),
                    isDefaultPayloadExchangeState(BOB, ALICE)
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
                    payloadMessageIds(ALICE, BOB)
                        == Set(message1.messageId, message2.messageId),
                    payloadMessageIds(BOB, ALICE) == Set()
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
                    hasInFlightPayload(ALICE, BOB),
                    not(hasInFlightPayload(BOB, ALICE))
                }
            )
}
