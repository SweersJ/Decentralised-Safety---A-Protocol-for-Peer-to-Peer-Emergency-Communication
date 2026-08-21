/// Define the payload exchange state type used by the batch protocol.
///
/// - @returns payload_exchange_state the payload exchange state type module
module payload_exchange_state {
    import payload_exchange_phase.* from "./payload_exchange_phase"

    /// Track the lifecycle phase and processing flags of a payload exchange.
    ///
    /// - @returns PayloadExchangeState the payload exchange lifecycle state
    type PayloadExchangeState = {
        phase: PayloadExchangePhase,
        messagesStored: bool,
        ackDetermined: bool
    }
}