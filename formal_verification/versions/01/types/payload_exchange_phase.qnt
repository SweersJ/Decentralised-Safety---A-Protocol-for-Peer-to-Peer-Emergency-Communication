/// Define the payload exchange phase type used by the batch protocol.
///
/// - @returns payload_exchange_phase the payload exchange phase type module
module payload_exchange_phase {
    /// Enumerate the phases of the batch payload exchange lifecycle.
    ///
    /// - @returns PayloadExchangePhase the current exchange phase
    type PayloadExchangePhase = Idle | MessagesAdded | MessagesSent | MessagesReceived | AckSent | AckReceived
}