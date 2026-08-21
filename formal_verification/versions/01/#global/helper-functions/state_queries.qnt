/// Define reusable pure queries over protocol state values.
///
/// - @returns state_query_helpers the shared state-query helper module
module state_query_helpers {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import message_id.* from "./../types/message_id"
    import node_state.* from "./../types/node_state"
    import payload.* from "./../types/payload"
    import payload_exchange_phase.* from "./../types/payload_exchange_phase"
    import payload_exchange_state.* from "./../types/payload_exchange_state"
    import messages.* from "./../messages/messages"

    /// Check whether a node-state value is empty.
    ///
    /// - @param NodeState state the node-state value to check
    /// - @returns bool whether the node state is empty
    pure def isDefaultNodeState(state: NodeState): bool = {
        and {
            state.messages.size() == 0,
            state.offers.size() == 0,
            state.requests.size() == 0,
        }
    }

    /// Check whether an optional payload is absent.
    ///
    /// - @param Option[Payload] payload the optional payload to check
    /// - @returns bool whether the payload is absent
    pure def isDefaultPayloadState(payload: Option[Payload]): bool = {
        payload == None
    }

    /// Check whether an exchange-state value equals the empty default state.
    ///
    /// - @param PayloadExchangeState state the exchange-state value to check
    /// - @returns bool whether the exchange state is empty
    pure def isDefaultPayloadExchangeState(state: PayloadExchangeState): bool = {
        and {
            state.phase == Idle,
            not(state.messagesStored),
            not(state.ackDetermined),
        }
    }

    /// Return the identifiers of all messages in an optional payload.
    ///
    /// - @param Option[Payload] payload the optional payload to inspect
    /// - @returns Set[MessageId] the payload message identifiers or an empty set
    pure def payloadMessageIds(payload: Option[Payload]): Set[MessageId] = {
        match payload {
            | Some(value) => getSetMessageIds(value.messages)
            | None => Set()
        }
    }

    /// Check whether an exchange state represents a sent message payload awaiting receipt.
    ///
    /// - @param PayloadExchangeState state the exchange state to check
    /// - @returns bool whether a message payload is in flight
    pure def hasInFlightMessagesPayload(state: PayloadExchangeState): bool = {
        state.phase == MessagesSent
    }

    /// Check whether an exchange state represents a message or acknowledgement payload in flight.
    ///
    /// - @param PayloadExchangeState state the exchange state to check
    /// - @returns bool whether any payload is in flight
    pure def hasInFlightPayload(state: PayloadExchangeState): bool = {
        or {
            state.phase == MessagesSent,
            state.phase == AckSent,
        }
    }
}
