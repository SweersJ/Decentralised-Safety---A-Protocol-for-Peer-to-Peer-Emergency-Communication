/// Define the safety predicate for self-directed payload state.
///
/// - @returns self_payloadState_is_always_empty_safety the shared safety-predicate module
module self_payloadState_is_always_empty_safety {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import node.* from "./../types/node"
    import payload.* from "./../types/payload"

    /// Assert that every node's payload addressed to itself is absent.
    ///
    /// - @param Set[Node] nodes the protocol participants to check
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the current per-peer payload state
    /// - @returns bool whether the proposition holds
    pure def self_payloadState_is_always_empty_predicate(
        nodes: Set[Node],
        currentPayloadState: Node -> (Node -> Option[Payload])
    ): bool =
        nodes.forall(n => currentPayloadState.get(n).get(n) == None)
}
