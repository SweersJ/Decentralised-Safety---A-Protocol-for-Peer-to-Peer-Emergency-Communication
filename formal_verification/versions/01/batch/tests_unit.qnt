/// Test batch protocol initialisation, guards, accessors, setters, and helpers.
///
/// -@return tests_unit the batch protocol unit-test module
module tests_unit {
    import batch.* from "batch"
    import messages.* from "./../messages/messages"

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    /// Associate each node with deterministic message identifiers for unit tests.
    ///
    /// Fixed input keeps the helper-function tests deterministic.
    ///
    /// -@return Node -> Set[MessageId] the test message identifiers by node
    pure val TEST_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId, message2.messageId),
        BOB -> Set(message2.messageId)
    )
    
    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise every protocol state variable with deterministic test messages.
    ///
    /// -@return bool whether the action is enabled and its transition constraints hold
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
    /// -@return bool whether the test passes
    run initNodeStateTest =
        initWithTestMessages
            .expect(
                nodeState.get(ALICE).get(BOB).messages == Set(message1, message2) and
                nodeState.get(BOB).get(ALICE).messages == Set(message2) and
                nodeState.get(ALICE).get(ALICE) == EMPTY_NODE_STATE and
                nodeState.get(BOB).get(BOB) == EMPTY_NODE_STATE
            )

    /// Test that every payload state is initially empty.
    ///
    /// -@return bool whether the test passes
    run initPayloadStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    payloadState.get(sender).get(receiver) == EMPTY_PAYLOAD
                ))
            )

    /// Test message-store initialisation from deterministic identifiers.
    ///
    /// -@return bool whether the test passes
    run initMessageStoreTest =
        initWithTestMessages
            .expect(
                messageStore.get(ALICE) == Set(message1, message2) and
                messageStore.get(BOB) == Set(message2)
            )

    /// Test that every payload exchange state is initially empty.
    ///
    /// -@return bool whether the test passes
    run initPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    payloadExchangeState.get(sender).get(receiver)
                        == EMPTY_PAYLOAD_EXCHANGE_STATE
                ))
            )

    /// Test that random initial identifiers cover each node and reference known messages.
    ///
    /// -@return bool whether the test passes
    run initRandomMessageIdsTest =
        initWithTestMessages
            .expect(
                initRandomMessageIds.keys() == NODES and
                NODES.forall(node =>
                    initRandomMessageIds.get(node).forall(
                        id => id.in(MESSAGES.keys())
                    )
                )
            )

    // ------------------------------------------------------------------------------------
    // TESTS - GUARD FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test that only distinct protocol participants form peer pairs.
    ///
    /// -@return bool whether the test passes
    run isPeerPairTest =
        initWithTestMessages
            .expect(
                isPeerPair(ALICE, BOB) and
                isPeerPair(BOB, ALICE) and
                not(isPeerPair(ALICE, ALICE)) and
                not(isPeerPair(BOB, BOB))
            )

    /// Test protocol guards in the initial state.
    ///
    /// -@return bool whether the test passes
    run initialGuardFunctionsTest =
        initWithTestMessages
            .expect(
                hasSyncDelta(ALICE, BOB) and
                canAddMessages(ALICE, BOB) and
                canAddMessages(BOB, ALICE) and // In this case Alice already has already all the messages of Bob, but that does Bob not know and therefore can also add the messages
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                not(canAckPayload(ALICE, BOB)) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                canIdle(ALICE, BOB)
            )

    /// Test protocol guards after messages are added to a payload.
    ///
    /// -@return bool whether the test passes
    run messagesAddedGuardFunctionsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                canSendMessagesPayload(ALICE, BOB) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                not(canAckPayload(ALICE, BOB)) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                not(canIdle(ALICE, BOB))
            )

    /// Test protocol guards after a message payload is received.
    ///
    /// -@return bool whether the test passes
    run messagesReceivedGuardFunctionsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                canStoreReceivedMessages(ALICE, BOB) and
                canDetermineAck(ALICE, BOB) and
                not(canAckPayload(ALICE, BOB)) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                not(canIdle(ALICE, BOB))
            )

    /// Test protocol guards after received messages are stored.
    ///
    /// -@return bool whether the test passes
    run receivedMessagesStoredGuardFunctionsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                canDetermineAck(ALICE, BOB) and
                not(canAckPayload(ALICE, BOB)) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                not(canIdle(ALICE, BOB))
            )
            
    /// Test acknowledgement-send guards when acknowledgement determination precedes storage.
    ///
    /// -@return bool whether the test passes
    run sendAckPayloadGuardFunctionsPath1Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                canAckPayload(ALICE, BOB) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                not(canIdle(ALICE, BOB))
            )
    
    /// Test acknowledgement-send guards when storage precedes acknowledgement determination.
    ///
    /// -@return bool whether the test passes
    run sendAckPayloadGuardFunctionsPath2Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                canAckPayload(ALICE, BOB) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                not(canIdle(ALICE, BOB))
            )
    
    /// Test acknowledgement-receive guards when acknowledgement determination precedes storage.
    ///
    /// -@return bool whether the test passes
    run receiveAckPayloadGuardFunctionsPath1Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                not(canAckPayload(ALICE, BOB)) and
                canReceiveAckPayload(ALICE, BOB) and
                not(canIdle(ALICE, BOB))
            )
    
    /// Test acknowledgement-receive guards when storage precedes acknowledgement determination.
    ///
    /// -@return bool whether the test passes
    run receiveAckPayloadGuardFunctionsPath2Test =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .expect(
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                not(canAckPayload(ALICE, BOB)) and
                canReceiveAckPayload(ALICE, BOB) and
                not(canIdle(ALICE, BOB))
            )
    
    /// Test idle guards after completing the determination-before-storage path.
    ///
    /// -@return bool whether the test passes
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
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                not(canAckPayload(ALICE, BOB)) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                canIdle(ALICE, BOB)
            )
    
    /// Test idle guards after completing the storage-before-determination path.
    ///
    /// -@return bool whether the test passes
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
                not(canAddMessages(ALICE, BOB)) and
                not(canSendMessagesPayload(ALICE, BOB)) and
                not(canReceiveMessagesPayload(ALICE, BOB)) and
                not(canStoreReceivedMessages(ALICE, BOB)) and
                not(canDetermineAck(ALICE, BOB)) and
                not(canAckPayload(ALICE, BOB)) and
                not(canReceiveAckPayload(ALICE, BOB)) and
                canIdle(ALICE, BOB)
            )

    // ------------------------------------------------------------------------------------
    // TESTS - GETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test retrieval of the node state for a peer pair.
    ///
    /// -@return bool whether the test passes
    run getNodeStateTest =
        initWithTestMessages
            .expect(
                val state = getNodeState(ALICE, BOB)

                state.offers.size() == 0 and
                state.requests.size() == 0 and
                state.messages.size() == 2
            )
    
    /// Test retrieval of an initially empty payload.
    ///
    /// -@return bool whether the test passes
    run getPayloadTest =
        initWithTestMessages
            .expect(
                val payload = getPayload(ALICE, BOB)

                payload.payloadId == 0 and
                payload.acks.size() == 0 and
                payload.offers.size() == 0 and
                payload.requests.size() == 0 and
                payload.messages.size() == 0
            )

    /// Test retrieval of an initial payload exchange state.
    ///
    /// -@return bool whether the test passes
    run getPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                val state = getPayloadExchangeState(ALICE, BOB)

                state.phase == Idle and
                not(state.messagesStored) and
                not(state.ackDetermined)
            )

    // ------------------------------------------------------------------------------------
    // TESTS - SETTER FUNCTIONS
    // ------------------------------------------------------------------------------------

    /// Test updating one peer pair's payload exchange phase.
    ///
    /// -@return bool whether the test passes
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
                    
                newPayloadExchangeState.get(ALICE).get(BOB).phase == MessagesSent and
                newPayloadExchangeState.get(BOB).get(ALICE).phase == Idle
            )

    /// Test updating one peer pair's messages-stored flag.
    ///
    /// -@return bool whether the test passes
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
                    
                newPayloadExchangeState.get(ALICE).get(BOB).messagesStored and
                not(newPayloadExchangeState.get(BOB).get(ALICE).messagesStored)
            )
            

    /// Test updating one peer pair's acknowledgement-determined flag.
    ///
    /// -@return bool whether the test passes
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
                    
                newPayloadExchangeState.get(ALICE).get(BOB).ackDetermined and
                not(newPayloadExchangeState.get(BOB).get(ALICE).ackDetermined)
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
    /// -@return bool whether the test passes
    run defaultNodeStateFunctionsTest =
        initWithTestMessages
            .expect(
                isDefaultNodeState(ALICE, ALICE) and
                isDefaultNodeState(BOB, BOB) and
                not(isDefaultNodeState(ALICE, BOB)) and
                not(isDefaultNodeState(BOB, ALICE))
            )

    /// Test recognition of default payload states.
    ///
    /// -@return bool whether the test passes
    run defaultPayloadStateFunctionsTest =
        initWithTestMessages
            .expect(
                isDefaultPayloadState(ALICE, ALICE) and
                isDefaultPayloadState(ALICE, BOB)
            )

    /// Test recognition of default payload exchange states.
    ///
    /// -@return bool whether the test passes
    run defaultPayloadExchangeStateFunctionsText = 
        initWithTestMessages
            .expect(
                isDefaultPayloadExchangeState(ALICE, ALICE) and
                isDefaultPayloadExchangeState(BOB, BOB) and
                isDefaultPayloadExchangeState(ALICE, BOB) and
                isDefaultPayloadExchangeState(BOB, ALICE)
            )

    /// Test extraction of message identifiers from directional payloads.
    ///
    /// -@return bool whether the test passes
    run payloadMessageIdsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .expect(
                payloadMessageIds(ALICE, BOB)
                    == Set(message1.messageId, message2.messageId) and
                payloadMessageIds(BOB, ALICE) == Set()
            )

    /// Test detection of an in-flight directional payload.
    ///
    /// -@return bool whether the test passes
    run hasInFlightPayloadTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(
                hasInFlightPayload(ALICE, BOB) and
                not(hasInFlightPayload(BOB, ALICE))
            )
}
