/// Define the per-peer node state type used by the batch protocol.
///
/// - @returns node_state the node state type module
module node_state {
    import message.* from "./message"
    import record_state.* from "./record_state"

    /// Represent a node's synchronisation knowledge for one peer.
    ///
    /// - @returns NodeState the per-peer synchronisation state
    type NodeState = {
        offers: Set[RecordState], //only for interactive TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //only for interactive TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }
}