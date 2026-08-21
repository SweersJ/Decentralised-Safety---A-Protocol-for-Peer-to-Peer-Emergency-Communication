/// Define the shared per-peer node-state variable.
///
/// - @returns node_state the per-peer node-state module
module node_state_variable {
    import node.* from "./../types/node"
    import node_state.* from "./../types/node_state"

    /// Track each sender's synchronisation knowledge for every receiver.
    /// (simulation of storing at node side what transport is expected for each node at the node side)
    ///
    /// - @returns Node -> (Node -> NodeState) the per-sender and per-receiver node states
    var nodeState: Node -> (Node -> NodeState)

}
