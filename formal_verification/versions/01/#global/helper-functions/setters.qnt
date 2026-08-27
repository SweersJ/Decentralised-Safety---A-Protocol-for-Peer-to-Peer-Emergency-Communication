/// Define reusable pure getter helpers.
///
/// - @returns setter_helpers the shared pure getter-helper module
module setter_helpers {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import message_id.* from "./../types/message_id"
    import message.* from "./../types/message"
    import node.* from "./../types/node"
    import node_state.* from "./../types/node_state"
    import payload.* from "./../types/payload"
    import payload_exchange_state.* from "./../types/payload_exchange_state"
    import payload_exchange_phase.* from "./../types/payload_exchange_phase"
    import record_state.* from "./../types/record_state"

    /// Return the exchange-state map with one sender-receiver entry replaced (only phase update).
    ///
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the current payload exchange state
    /// - @param Node sender the sender entry to update
    /// - @param Node receiver the receiver entry to update
    /// - @param PayloadExchangePhase newPayloadExchangePhase the replacement exchange phase
    /// - @returns Node -> (Node -> PayloadExchangeState) the computed result
    pure def setPayloadExchangeStatePhase(
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState),
        sender: Node, 
        receiver: Node, 
        newPayloadExchangePhase: PayloadExchangePhase
    ): Node -> (Node -> PayloadExchangeState) = {
        currentPayloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver, 
                receiverState => {
                    ...receiverState,
                    phase: newPayloadExchangePhase
                }
            )
        )
    }

    /// Return the exchange-state map with one sender-receiver entry replaced (only ackDetermined update).
    ///
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the current payload exchange state
    /// - @param Node sender the sender entry to update
    /// - @param Node receiver the receiver entry to update
    /// - @param bool newAckDetermined whether acknowledgements have been determined
    /// - @returns Node -> (Node -> PayloadExchangeState) the computed result
    pure def setPayloadExchangeStateAckDetermined(
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState),
        sender: Node, 
        receiver: Node, 
        newAckDetermined: bool
    ): Node -> (Node -> PayloadExchangeState) = {
        currentPayloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver, 
                receiverState => {
                    ...receiverState,
                    ackDetermined: newAckDetermined
                }
            )
        )
    }

    /// Return the exchange-state map with one sender-receiver entry replaced (only messagesStored update).
    ///
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the current payload exchange state
    /// - @param Node sender the sender entry to update
    /// - @param Node receiver the receiver entry to update
    /// - @param bool newMessagesStored whether received messages have been stored
    /// - @returns Node -> (Node -> PayloadExchangeState) the computed result
    pure def setPayloadExchangeStateMessagesStored(
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState),
        sender: Node, 
        receiver: Node, 
        newMessagesStored: bool
    ): Node -> (Node -> PayloadExchangeState) = {
        currentPayloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver, 
                receiverState => {
                    ...receiverState,
                    messagesStored: newMessagesStored
                }
            )
        )
    }

    /// Return the exchange-state map with one sender-receiver entry replaced.
    ///
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the current payload exchange state
    /// - @param Node sender the sender entry to update
    /// - @param Node receiver the receiver entry to update
    /// - @param PayloadExchangePhase newPayloadExchangePhase the replacement exchange phase
    /// - @param bool newMessagesStored whether received messages have been stored
    /// - @param bool newAckDetermined whether acknowledgements have been determined
    /// - @returns Node -> (Node -> PayloadExchangeState) the computed result
    pure def setPayloadExchangeState(
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState),
        sender: Node,
        receiver: Node,
        newPayloadExchangePhase: PayloadExchangePhase,
        newMessagesStored: bool,
        newAckDetermined: bool
    ): Node -> (Node -> PayloadExchangeState) = {
        currentPayloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver,
                receiverState => {
                    phase: newPayloadExchangePhase,
                    messagesStored: newMessagesStored,
                    ackDetermined: newAckDetermined
                }
            )
        )
    }
}
