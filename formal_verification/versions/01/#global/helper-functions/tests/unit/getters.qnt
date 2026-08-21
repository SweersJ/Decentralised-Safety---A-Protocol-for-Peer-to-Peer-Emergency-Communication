/// Test pure getter helpers with explicit state values.
///
/// - @returns getters_tests the instance-independent getter unit-test module
module getters_tests {
    import unit_fixture.* from "fixture"

    /// Test retrieval of the node state for a peer pair.
    ///
    /// - @returns bool whether the test passes
    run getNodeStateTest =
        val expectedState: NodeState = {
            offers: Set(),
            requests: Set(),
            messages: Set(message1, message2),
        }
        val currentNodeState = Map(ALICE -> Map(BOB -> expectedState))

        getNodeState(currentNodeState, ALICE, BOB) == expectedState

    /// Test retrieval of a directional payload.
    ///
    /// - @returns bool whether the test passes
    run getPayloadTest =
        val currentPayloadState = Map(ALICE -> Map(BOB -> None))

        getPayload(currentPayloadState, ALICE, BOB) == None

    /// Test retrieval of a directional payload-exchange state.
    ///
    /// - @returns bool whether the test passes
    run getPayloadExchangeStateTest =
        val currentPayloadExchangeState = Map(
            ALICE -> Map(BOB -> EMPTY_PAYLOAD_EXCHANGE_STATE)
        )

        getPayloadExchangeState(currentPayloadExchangeState, ALICE, BOB)
            == EMPTY_PAYLOAD_EXCHANGE_STATE
}
