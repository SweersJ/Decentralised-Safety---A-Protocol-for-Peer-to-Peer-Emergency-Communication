/// Define the shared payload-exchange lifecycle state variable.
///
/// - @returns payload_exchange_state_variable the payload-exchange state module
module payload_exchange_state_variable {
    import node.* from "./../types/node"
    import payload_exchange_state.* from "./../types/payload_exchange_state"

    /// Track the payload exchange lifecycle for every sender-receiver pair.
    ///
    /// - @returns Node -> (Node -> PayloadExchangeState) the exchange states indexed by sender and receiver
    var payloadExchangeState: Node -> (Node -> PayloadExchangeState)

}
