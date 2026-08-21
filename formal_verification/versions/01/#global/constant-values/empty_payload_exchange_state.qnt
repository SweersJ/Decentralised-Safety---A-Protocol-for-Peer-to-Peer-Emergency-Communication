/// Define the default payload exchange state shared by the synchronisation protocols.
///
/// - @returns empty_payload_exchange_state the empty payload exchange-state constant module
module empty_payload_exchange_state {
    import payload_exchange_phase.* from "./../types/payload_exchange_phase"
    import payload_exchange_state.* from "./../types/payload_exchange_state"

    /// Provide the default idle and unprocessed payload exchange state.
    ///
    /// - @returns PayloadExchangeState the empty exchange-state value
    pure val EMPTY_PAYLOAD_EXCHANGE_STATE: PayloadExchangeState = {
        phase: Idle,
        messagesStored: false,
        ackDetermined: false
    }
}
