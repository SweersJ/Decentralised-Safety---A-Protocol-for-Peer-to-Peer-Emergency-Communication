/// Define reusable state-initialization helpers for a configured set of nodes.
///
/// - @param Set[Node] INIT_NODES the protocol participants included in the initialized state
/// - @returns init_helpers the configured initialization-helper module
module init_helpers {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import message_id.* from "./../types/message_id"
    import message.* from "./../types/message"
    import payload.* from "./../types/payload"
    import node_state.* from "./../types/node_state"
    import node.* from "./../types/node"
    import payload_exchange_state.* from "./../types/payload_exchange_state"
    import messages.* from "./../messages/messages"
    import empty_node_state.* from "./../constant-values/empty_node_state"
    import empty_payload_exchange_state.* from "./../constant-values/empty_payload_exchange_state"

    /// Provide all protocol participants included in initialized state.
    ///
    /// - @returns Set[Node] the modeled nodes
    const INIT_NODES: Set[Node]

    /// Build the initial per-peer node state from the messages assigned to each node.
    ///
    /// - @param Node -> Set[MessageId] randomMessageIds the message identifiers assigned to each node
    /// - @returns Node -> (Node -> NodeState) the computed result
    pure def initNodeState(randomMessageIds: Node -> Set[MessageId]): Node -> (Node -> NodeState) = {
        INIT_NODES.mapBy(
            sender => INIT_NODES.mapBy(
                receiver => {
                    ...EMPTY_NODE_STATE,
                    messages: if (sender != receiver) getMessages(randomMessageIds.get(sender)) else EMPTY_NODE_STATE.messages
                }
            )
        )
    }

    /// Build an empty payload for every sender-receiver pair.
    ///
    /// - @returns Node -> (Node -> Option[Payload]) the computed result
    pure def initPayloadState(): Node -> (Node -> Option[Payload]) = {
        INIT_NODES.mapBy(
            _ => INIT_NODES.mapBy(
                _ => None
            )
        )
    }

    /// Populate each node's message store from its assigned message identifiers.
    ///
    /// - @param Node -> Set[MessageId] randomMessageIds the message identifiers assigned to each node
    /// - @returns Node -> Set[Message] the computed result
    pure def initMessageStore(randomMessageIds: Node -> Set[MessageId]): Node -> Set[Message] = {
        INIT_NODES.mapBy(
            node => getMessages(randomMessageIds.get(node))
        )
    }

    /// Initialise every sender-receiver exchange to the empty idle state.
    ///
    /// - @returns Node -> (Node -> PayloadExchangeState) the computed result
    pure def initPayloadExchangeState(): Node -> (Node -> PayloadExchangeState) = {
        INIT_NODES.mapBy(
            sender => INIT_NODES.mapBy(
                receiver => EMPTY_PAYLOAD_EXCHANGE_STATE
            )
        )
    }

    /// Choose an initial set of message identifiers for every node.
    ///
    /// - @returns Node -> Set[MessageId] the computed result
    pure def initRandomMessageIds(): Node -> Set[MessageId] = {
        INIT_NODES.mapBy(n => getRandomMessageIds)
    }
}
