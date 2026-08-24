/// Define reusable pure getter helpers.
///
/// - @returns getter_helpers the shared pure getter-helper module
module getter_helpers {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import message_id.* from "./../types/message_id"
    import message.* from "./../types/message"
    import node.* from "./../types/node"
    import node_state.* from "./../types/node_state"
    import payload.* from "./../types/payload"
    import payload_exchange_state.* from "./../types/payload_exchange_state"
    import record_state.* from "./../types/record_state"

    /// Return the messages stored by a node from a message-store value.
    ///
    /// - @param Node -> Set[Message] currentMessageStore the message store to query
    /// - @param Node node the node whose messages are returned
    /// - @returns Set[Message] the messages stored by the node
    pure def getMessagesMessageStore(
        currentMessageStore: Node -> Set[Message],
        node: Node
    ): Set[Message] = {
        currentMessageStore.get(node)
    }

    /// Return a sender's synchronisation state from a node-state value.
    ///
    /// - @param Node -> (Node -> NodeState) currentNodeState the per-peer node state to query
    /// - @param Node sender the node maintaining the synchronisation state
    /// - @param Node receiver the peer represented by that state
    /// - @returns NodeState the selected synchronisation state
    pure def getNodeState(
        currentNodeState: Node -> (Node -> NodeState),
        sender: Node,
        receiver: Node
    ): NodeState = {
        currentNodeState.get(sender).get(receiver)
    }

    /// Return an optional payload from a payload-state value.
    ///
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the per-peer payload state to query
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns Option[Payload] the selected payload when one exists, otherwise None
    pure def getPayload(
        currentPayloadState: Node -> (Node -> Option[Payload]),
        sender: Node,
        receiver: Node
    ): Option[Payload] = {
        currentPayloadState.get(sender).get(receiver)
    }

    /// Return the messages from an optional payload in a payload-state value.
    ///
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the per-peer payload state to query
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns Set[Message] the payload messages or an empty set
    pure def getPayloadMessages(
        currentPayloadState: Node -> (Node -> Option[Payload]),
        sender: Node,
        receiver: Node
    ): Set[Message] = {
        match getPayload(currentPayloadState, sender, receiver) {
            | Some(payload) => payload.messages
            | None => Set()
        }
    }

    /// Return the acknowledgements from an optional payload in a payload-state value.
    ///
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the per-peer payload state to query
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns Set[MessageId] the acknowledgement identifiers or an empty set
    pure def getPayloadAcks(
        currentPayloadState: Node -> (Node -> Option[Payload]),
        sender: Node,
        receiver: Node
    ): Set[MessageId] = {
        match getPayload(currentPayloadState, sender, receiver) {
            | Some(payload) => payload.acks
            | None => Set()
        }
    }

    /// Return the offers from an optional payload in a payload-state value.
    ///
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the per-peer payload state to query
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns Set[MessageId] the offered message identifiers or an empty set
    pure def getPayloadOffers(
        currentPayloadState: Node -> (Node -> Option[Payload]), sender: Node, receiver: Node
    ): Set[MessageId] = {
        match getPayload(currentPayloadState, sender, receiver) {
            | Some(payload) => payload.offers
            | None => Set()
        }
    }

    /// Return the requests from an optional payload in a payload-state value.
    ///
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the per-peer payload state to query
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns Set[MessageId] the requested message identifiers or an empty set
    pure def getPayloadRequests(
        currentPayloadState: Node -> (Node -> Option[Payload]), sender: Node, receiver: Node
    ): Set[MessageId] = {
        match getPayload(currentPayloadState, sender, receiver) {
            | Some(payload) => payload.requests
            | None => Set()
        }
    }

    /// Return an exchange state from a payload-exchange-state value.
    ///
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the per-peer exchange state to query
    /// - @param Node sender the payload sender
    /// - @param Node receiver the payload receiver
    /// - @returns PayloadExchangeState the selected exchange state
    pure def getPayloadExchangeState(
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState),
        sender: Node,
        receiver: Node
    ): PayloadExchangeState = {
        currentPayloadExchangeState.get(sender).get(receiver)
    }

    /// Return the message identifiers represented by a set of record states.
    ///
    /// - @param Set[RecordState] recordStates the record states from which to extract message identifiers
    /// - @returns Set[MessageId] the represented message identifiers
    pure def getRecordStateMessageIds(recordStates: Set[RecordState]): Set[MessageId] = {
        recordStates.map(recordState => recordState.messageId)
    }
}
