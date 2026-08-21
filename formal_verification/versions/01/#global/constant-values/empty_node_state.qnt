/// Define the default per-peer node state shared by the synchronisation protocols.
///
/// - @returns empty_node_state the empty node-state constant module
module empty_node_state {
    import node_state.* from "./../types/node_state"

    /// Provide the default per-peer node state containing no synchronisation data.
    ///
    /// - @returns NodeState the empty node-state value
    pure val EMPTY_NODE_STATE: NodeState = {
        offers: Set(),
        requests: Set(),
        messages: Set()
    }
}
