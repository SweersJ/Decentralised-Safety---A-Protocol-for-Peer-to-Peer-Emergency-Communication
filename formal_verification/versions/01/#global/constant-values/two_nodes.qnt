/// Define the two nodes shared by concrete protocol instances.
///
/// - @returns two_nodes the shared two-node constant-values module
module two_nodes {
    import node.* from "./../types/node"

    /// Identify Alice in a concrete two-node protocol instance.
    ///
    /// - @returns Node Alice's node identifier
    pure val ALICE: Node = "Alice"

    /// Identify Bob in a concrete two-node protocol instance.
    ///
    /// - @returns Node Bob's node identifier
    pure val BOB: Node = "Bob"

    /// Select the two nodes participating in a concrete protocol instance.
    ///
    /// - @returns Set[Node] the configured protocol participants
    pure val TWO_NODES: Set[Node] = Set(ALICE, BOB)
}
