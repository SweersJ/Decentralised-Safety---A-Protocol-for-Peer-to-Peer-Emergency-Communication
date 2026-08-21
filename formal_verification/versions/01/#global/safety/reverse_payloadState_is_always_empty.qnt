/// Define the safety predicate for reverse-direction payload state.
///
/// - @returns reverse_payloadState_is_always_empty_safety the shared safety-predicate module
module reverse_payloadState_is_always_empty_safety {
    import basicSpells.* from "./../../../../spells/basicSpells"
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
                    (
                        // Allow both directions to be empty only when both directions are idle.
                        (
                            (
                                currentPayloadExchangeState.get(sender).get(receiver).phase == Idle or
                                currentPayloadExchangeState.get(sender).get(receiver).phase == AckReceived
                            )
                            and
                            (
                                currentPayloadExchangeState.get(receiver).get(sender).phase == Idle or
                                currentPayloadExchangeState.get(receiver).get(sender).phase == AckReceived
                            )
                        )
                        or
                        // During sync activity, at least one direction must contain a payload.
                        (
                            currentPayloadState.get(sender).get(receiver) != None or
                            currentPayloadState.get(receiver).get(sender) != None
                        )
                    )
            )
        )
}
