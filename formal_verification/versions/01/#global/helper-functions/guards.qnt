/// Define reusable protocol guard helpers.
///
/// - @returns guard_helpers the shared protocol guard-helper module
module guard_helpers {
    import node.* from "./../types/node"

    /// Check whether a sender and receiver are distinct peers.
    ///
    /// - @param Node sender the node sending the payload
    /// - @param Node receiver the node receiving the payload
    /// - @returns bool whether the nodes form a valid peer pair
    pure def isPeerPair(sender: Node, receiver: Node): bool = {
        sender != receiver
    }
}
