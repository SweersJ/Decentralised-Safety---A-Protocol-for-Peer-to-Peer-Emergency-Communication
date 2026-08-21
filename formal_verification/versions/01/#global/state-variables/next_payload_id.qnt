/// Define the shared payload-identifier generator state variable.
///
/// - @returns next_payload_id the payload-identifier generator state module
module next_payload_id {
    /// Track the payload identifier reserved for the next send action.
    ///
    /// TODO: add the payload generator.
    ///
    /// - @returns int the next payload id for the next payload to be sent
    var nextPayloadId: int
}
