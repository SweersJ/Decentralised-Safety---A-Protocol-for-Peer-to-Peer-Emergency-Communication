/// Define the safety predicate for self-directed node state.
///
/// - @returns self_nodeState_is_always_empty_safety the shared safety-predicate module
module self_nodeState_is_always_empty_safety {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import node.* from "./../types/node"
    import node_state.* from "./../types/node_state"

    /// Assert that every node's synchronisation state for itself is empty.
    ///
    /// - @param Set[Node] nodes the protocol participants to check
    /// - @param Node -> (Node -> NodeState) currentNodeState the current per-peer node state
    /// - @returns bool whether the proposition holds
    pure def self_nodeState_is_always_empty_predicate(
        nodes: Set[Node],
        currentNodeState: Node -> (Node -> NodeState)
    ): bool =
        nodes.forall(n => {
            val selfState = currentNodeState.get(n).get(n)
            and {
                selfState.messages.size() == 0,
                selfState.offers.size() == 0,
                selfState.requests.size() == 0,
            }
        })
}
