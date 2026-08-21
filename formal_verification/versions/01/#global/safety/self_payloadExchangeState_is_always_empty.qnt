/// Define the safety predicate for self-directed payload-exchange state.
///
/// - @returns self_payloadExchangeState_is_always_empty_safety the shared safety-predicate module
module self_payloadExchangeState_is_always_empty_safety {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import node.* from "./../types/node"
    import payload_exchange_phase.* from "./../types/payload_exchange_phase"
    import payload_exchange_state.* from "./../types/payload_exchange_state"

    /// Assert that every node's exchange state with itself remains at its default.
    ///
    /// - @param Set[Node] nodes the protocol participants to check
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the current per-peer exchange state
    /// - @returns bool whether the proposition holds
    pure def self_payloadExchangeState_is_always_empty_predicate(
        nodes: Set[Node],
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState)
    ): bool =
        nodes.forall(n => {
            val selfState = currentPayloadExchangeState.get(n).get(n)
            and {
                selfState.phase == Idle,
                not(selfState.messagesStored),
                not(selfState.ackDetermined),
            }
        })
}
