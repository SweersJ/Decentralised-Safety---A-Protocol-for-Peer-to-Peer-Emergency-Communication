/// Test batch protocol state setters.
///
/// - @returns setters_tests the focused unit-test module
module setters_tests {
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
                val currentPayloadExchangeStateReverse = getPayloadExchangeState(payloadExchangeState, BOB, ALICE)
                
                val newPayloadExchangeState = setPayloadExchangeState(
                    ALICE,
                    BOB,
                    MessagesSent,
                    currentPayloadExchangeState.messagesStored,
                    true
                )

                and {
                    not(currentPayloadExchangeState.ackDetermined),
                    not(currentPayloadExchangeStateReverse.ackDetermined),
                    newPayloadExchangeState.get(ALICE).get(BOB).ackDetermined,
                    not(newPayloadExchangeState.get(BOB).get(ALICE).ackDetermined),
                }
            )
}
