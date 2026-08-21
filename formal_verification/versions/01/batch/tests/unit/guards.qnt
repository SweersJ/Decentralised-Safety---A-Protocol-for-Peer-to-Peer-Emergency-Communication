/// Test batch protocol transition guards.
///
/// - @returns guards_tests the focused unit-test module
module guards_tests {
    import unit_fixture.* from "./../../../#global/helper-functions/tests/unit/fixture"

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
    // TESTS - GUARD FUNCTIONS
    // ------------------------------------------------------------------------------------

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
}
