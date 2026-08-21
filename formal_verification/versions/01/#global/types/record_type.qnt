
module record_type {
    /// Classify a synchronisation record as an offer or request.
    /// ! only for interactive !
    ///
    /// - @returns RecordType the record classification
    type RecordType = OfferRecord | RequestRecord | MessageRecord | AckRecord    
}