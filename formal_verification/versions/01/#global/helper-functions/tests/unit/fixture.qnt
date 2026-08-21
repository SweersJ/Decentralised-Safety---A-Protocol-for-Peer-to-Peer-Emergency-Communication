/// Provide the shared deterministic batch unit-test fixture.
///
/// - @returns unit_fixture the shared batch unit-test fixture module
module unit_fixture {
    import message_id.* from "./../../../types/message_id"
    import message.* from "./../../../types/message"
    import payload_id.* from "./../../../types/payload_id"
    import payload.* from "./../../../types/payload"
    import node_state.* from "./../../../types/node_state"
    import node.* from "./../../../types/node"
    import payload_exchange_phase.* from "./../../../types/payload_exchange_phase"
    import payload_exchange_state.* from "./../../../types/payload_exchange_state"
    import messages.* from "./../../../messages/messages"
    import empty_node_state.* from "./../../../constant-values/empty_node_state"
    import empty_payload_exchange_state.* from "./../../../constant-values/empty_payload_exchange_state"
    import guard_helpers.* from "./../../../helper-functions/guards"
    import getter_helpers.* from "./../../../helper-functions/getters"
    import state_query_helpers.* from "./../../../helper-functions/state_queries"
    import basicSpells.* from "./../../../../../../spells/basicSpells"
    export message_id.*
    export message.*
    export payload_id.*
    export payload.*
    export node_state.*
    export node.*
    export payload_exchange_phase.*
    export payload_exchange_state.*
    export messages.*
    export empty_node_state.*
    export empty_payload_exchange_state.*
    export guard_helpers.*
    export getter_helpers.*
    export state_query_helpers.*
    export basicSpells.*

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

}
