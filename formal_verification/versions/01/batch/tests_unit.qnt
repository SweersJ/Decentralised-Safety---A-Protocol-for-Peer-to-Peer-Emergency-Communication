module tests_unit {
    import batch.* from "batch"
    import messages.* from "./../messages/messages"

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    // Fixed input keeps the helper-function tests deterministic.
    pure val TEST_MESSAGE_IDS: Node -> Set[MessageId] = Map(
        ALICE -> Set(message1.messageId, message2.messageId),
        BOB -> Set(message2.messageId)
    )
    
    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    action initWithTestMessages() = all {
        nodeState' = initNodeState(TEST_MESSAGE_IDS),
        payloadState' = initPayloadState,
        messageStore' = initMessageStore(TEST_MESSAGE_IDS),
        payloadExchangeState' = initPayloadExchangeState,
    }

    // ------------------------------------------------------------------------------------
    // TESTS - INIT FUNCTIONS
    // ------------------------------------------------------------------------------------

    run initNodeStateTest =
        initWithTestMessages
            .expect(
                nodeState.get(ALICE).get(BOB).messages == Set(message1, message2) and
                nodeState.get(BOB).get(ALICE).messages == Set(message2) and
                nodeState.get(ALICE).get(ALICE) == EMPTY_NODE_STATE and
                nodeState.get(BOB).get(BOB) == EMPTY_NODE_STATE
            )

    run initPayloadStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    payloadState.get(sender).get(receiver) == EMPTY_PAYLOAD
                ))
            )

    run initMessageStoreTest =
        initWithTestMessages
            .expect(
                messageStore.get(ALICE) == Set(message1, message2) and
                messageStore.get(BOB) == Set(message2)
            )

    run initPayloadExchangeStateTest =
        initWithTestMessages
            .expect(
                NODES.forall(sender => NODES.forall(receiver =>
                    payloadExchangeState.get(sender).get(receiver)
                        == EMPTY_PAYLOAD_EXCHANGE_STATE
                ))
            )

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

    run isPeerPairTest =
        initWithTestMessages
            .expect(
                isPeerPair(ALICE, BOB) and
                isPeerPair(BOB, ALICE) and
                not(isPeerPair(ALICE, ALICE)) and
                not(isPeerPair(BOB, BOB))
            )

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

    run getNodeStateTest =
        initWithTestMessages
            .expect(
                val state = getNodeState(ALICE, BOB)

                state.offers.size() == 0 and
                state.requests.size() == 0 and
                state.messages.size() == 2
            )
    
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

    run defaultNodeStateFunctionsTest =
        initWithTestMessages
            .expect(
                isDefaultNodeState(ALICE, ALICE) and
                isDefaultNodeState(BOB, BOB) and
                not(isDefaultNodeState(ALICE, BOB)) and
                not(isDefaultNodeState(BOB, ALICE))
            )

    run defaultPayloadStateFunctionsTest =
        initWithTestMessages
            .expect(
                isDefaultPayloadState(ALICE, ALICE) and
                isDefaultPayloadState(ALICE, BOB)
            )

    run defaultPayloadExchangeStateFunctionsText = 
        initWithTestMessages
            .expect(
                isDefaultPayloadExchangeState(ALICE, ALICE) and
                isDefaultPayloadExchangeState(BOB, BOB) and
                isDefaultPayloadExchangeState(ALICE, BOB) and
                isDefaultPayloadExchangeState(BOB, ALICE)
            )

    run payloadMessageIdsTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .expect(
                payloadMessageIds(ALICE, BOB)
                    == Set(message1.messageId, message2.messageId) and
                payloadMessageIds(BOB, ALICE) == Set()
            )

    run hasInFlightPayloadTest =
        initWithTestMessages
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .expect(
                hasInFlightPayload(ALICE, BOB) and
                not(hasInFlightPayload(BOB, ALICE))
            )
}
