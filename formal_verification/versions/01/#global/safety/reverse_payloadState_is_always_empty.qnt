/// Define the safety predicate for reverse-direction payload state.
///
/// - @returns reverse_payloadState_is_always_empty_safety the shared safety-predicate module
module reverse_payloadState_is_always_empty_safety {
    import basicSpells.* from "./../../../../spells/basicSpells"
    import getter_helpers.* from "./../helper-functions/getters"
    import node.* from "./../types/node"
    import payload.* from "./../types/payload"
    import payload_exchange_phase.* from "./../types/payload_exchange_phase"
    import payload_exchange_state.* from "./../types/payload_exchange_state"

    /// Assert the permitted relationship between forward and reverse payload state.
    ///
    /// - @param Set[Node] nodes the protocol participants to check
    /// - @param Node -> (Node -> Option[Payload]) currentPayloadState the current per-peer payload state
    /// - @param Node -> (Node -> PayloadExchangeState) currentPayloadExchangeState the current per-peer exchange state
    /// - @returns bool whether the proposition holds
    pure def reverse_payloadState_is_always_empty_predicate(
        nodes: Set[Node],
        currentPayloadState: Node -> (Node -> Option[Payload]),
        currentPayloadExchangeState: Node -> (Node -> PayloadExchangeState)
    ): bool =
        nodes.forall(
            sender => nodes.forall(
                receiver =>
                    sender != receiver implies
                    {
                        val forwardPhase =
                            getPayloadExchangeState(currentPayloadExchangeState, sender, receiver).phase
                        val reversePhase =
                            getPayloadExchangeState(currentPayloadExchangeState, receiver, sender).phase
                        val forwardPayload = getPayload(currentPayloadState, sender, receiver)
                        val reversePayload = getPayload(currentPayloadState, receiver, sender)
                        val forwardInactive = forwardPhase == Idle or forwardPhase == AckReceived
                        val reverseInactive = reversePhase == Idle or reversePhase == AckReceived

                        or {
                            // Both payloads may be empty when neither direction is active.
                            forwardInactive and reverseInactive,
                            // A single active direction owns the only in-flight payload.
                            not(forwardInactive) and reverseInactive
                                and forwardPayload != None and reversePayload == None,
                            forwardInactive and not(reverseInactive)
                                and forwardPayload == None and reversePayload != None,
                            // Concurrent synchronization permits one payload in each direction.
                            not(forwardInactive) and not(reverseInactive)
                                and forwardPayload != None and reversePayload != None,
                        }
                    }
            )
        )
}
