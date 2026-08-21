/// Define the payload identifier type used by the batch protocol.
///
/// - @returns payload_id the payload identifier type module
module payload_id {
    /// Identify a protocol payload with an id encoded as integer instead of UUID.
    ///
    /// - @returns PayloadId the integer payload identifier
    type PayloadId = int
}