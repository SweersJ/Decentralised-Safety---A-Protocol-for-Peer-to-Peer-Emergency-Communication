/// Model the two-node interactive message synchronisation and acknowledgement protocol.
///
/// - @param Set[Node] NODES the protocol participants included in the model
/// - @param Node -> Set[MessageId] RANDOM_MESSAGE_IDS the initial message identifiers assigned to each node
/// - @returns interactive the protocol module
module interactive {
    // > General
    import basicSpells.* from "./../../../spells/basicSpells"
    // > Types
    import message_id.* from "./../#global/types/message_id"
    import message.* from "./../#global/types/message"
    import payload_id.* from "./../#global/types/payload_id"
    import payload.* from "./../#global/types/payload"
    import node_state.* from "./../#global/types/node_state"
    import node.* from "./../#global/types/node"
    import payload_exchange_phase.* from "./../#global/types/payload_exchange_phase"
    import payload_exchange_state.* from "./../#global/types/payload_exchange_state"
    import record_type.* from "./../#global/types/record_type"
    import record_state.* from "./../#global/types/record_state"
    // > Messages
    import messages.* from "./../#global/messages/messages"
    // > Helper functions
    import init_helpers(INIT_NODES = NODES).* from "./../#global/helper-functions/init"
    import guard_helpers.* from "./../#global/helper-functions/guards"
    import getter_helpers.* from "./../#global/helper-functions/getters"
    import setter_helpers.* from "./../#global/helper-functions/setters"
    import state_query_helpers.* from "./../#global/helper-functions/state_queries"
    // > Safety propositions
    import self_nodeState_is_always_empty_safety.* from "./../#global/safety/self_nodeState_is_always_empty"
    import self_payloadState_is_always_empty_safety.* from "./../#global/safety/self_payloadState_is_always_empty"
    import reverse_payloadState_is_always_empty_safety.* from "./../#global/safety/reverse_payloadState_is_always_empty"
    import self_payloadExchangeState_is_always_empty_safety.* from "./../#global/safety/self_payloadExchangeState_is_always_empty"
    // > State variables
    import message_store.* from "./../#global/state-variables/message_store"
    import node_state_variable.* from "./../#global/state-variables/node_state"
    import payload_state.* from "./../#global/state-variables/payload_state"
    import payload_exchange_state_variable.* from "./../#global/state-variables/payload_exchange_state"
    // > Exports
    export message_store.*
    export node_state_variable.*
    export payload_state.*
    export payload_exchange_state_variable.*
    // import next_payload_id.* from "./../#global/state-variables/next_payload_id" // only for retransmission

    // ------------------------------------------------------------------------------------
    // CONSTANT VARIABLES
    // ------------------------------------------------------------------------------------

    /// Provide all protocol participants configured by an importing module.
    ///
    /// - @returns Set[Node] the modeled nodes
    const NODES: Set[Node]

    /// Provide the initial message identifiers configured for every protocol participant.
    ///
    /// - @returns Node -> Set[MessageId] the initial message identifiers indexed by node
    const RANDOM_MESSAGE_IDS: Node -> Set[MessageId]

    // ------------------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // ------------------------------------------------------------------------------------

    // > GUARD FUNCTIONS

    /// Check whether a sender may advertise its pending messages to a peer.
    ///
    /// - @param Node sender the node creating offers
    /// - @param Node receiver the destination peer
    /// - @returns bool whether offers can be added
    def canAddOffers(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getNodeState(nodeState, sender, receiver).messages.size() > 0,
            getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == Idle,
        }
    }

    /// Check whether an offer payload may advance to the receiver.
    ///
    /// - @param Node sender the node advertising messages
    /// - @param Node receiver the destination peer
    /// - @returns bool whether the offers can be sent
    def canSendOffersPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadOffers(payloadState, sender, receiver).size() > 0,
            getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == OffersAdded,
        }
    }

    /// Check whether an in-flight offer payload may be received.
    ///
    /// - @param Node sender the node advertising messages
    /// - @param Node receiver the node receiving the offers
    /// - @returns bool whether the offers can be received
    def canReceiveOffersPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == OffersSent
        }
    }

    /// Check whether the receiver may request offered messages it does not store.
    ///
    /// - @param Node sender the node that supplied the offers
    /// - @param Node receiver the node selecting requests
    /// - @returns bool whether requests can be determined
    def canDetermineRequests(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == OffersReceived
        }
    }

    /// Check whether a request payload may advance to the sender.
    ///
    /// - @param Node sender the node that supplied the offers
    /// - @param Node receiver the node returning requests
    /// - @returns bool whether the requests can be sent
    def canSendRequestsPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == RequestAdded
        }
    }

    /// Check whether an in-flight request payload may be received.
    ///
    /// - @param Node sender the node receiving the requests
    /// - @param Node receiver the node that selected them
    /// - @returns bool whether the requests can be received
    def canReceiveRequestsPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == RequestSent
        }
    }

    /// Check whether a sender-receiver pair has messages available for synchronisation.
    ///
    /// - @param Node sender the node whose messages are synchronized
    /// - @param Node receiver the destination peer
    /// - @returns bool the computed result
    def hasSyncDelta(sender: Node, receiver: Node): bool = {
        and {
            getMessagesMessageStore(messageStore, sender).size() > 0,
            getNodeState(nodeState, sender,receiver).messages.size() > 0,
        }
    }

    /// Check whether pending messages may be added to the pair's payload.
    ///
    /// - @param Node sender the node adding messages
    /// - @param Node receiver the destination peer
    /// - @returns bool the computed result
    def canAddMessages(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            hasSyncDelta(sender, receiver),
            getPayloadRequests(payloadState, sender, receiver).size() > 0,
            getPayloadExchangeState(payloadExchangeState, sender,receiver).phase == RequestReceived,
        }
    }

    /// Check whether the pair's populated message payload may be sent.
    ///
    /// - @param Node sender the node sending the payload
    /// - @param Node receiver the destination peer
    /// - @returns bool the computed result
    def canSendMessagesPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            hasSyncDelta(sender, receiver),
            getPayloadMessages(payloadState, sender, receiver).size() != 0,
            getNodeState(nodeState, sender,receiver).messages.size() != 0,
            getPayloadExchangeState(payloadExchangeState, sender,receiver).phase == MessagesAdded,
        }
        
    }

    /// Check whether the receiver may receive the sender's in-flight message payload.
    ///
    /// - @param Node sender the node that sent the payload
    /// - @param Node receiver the node receiving the payload
    /// - @returns bool the computed result
    def canReceiveMessagesPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadExchangeState(payloadExchangeState, sender,receiver).phase == MessagesSent,
        }
    }

    /// Check whether a received payload's messages may be stored by the receiver.
    ///
    /// - @param Node sender the node that sent the payload
    /// - @param Node receiver the node storing the messages
    /// - @returns bool the computed result
    def canStoreReceivedMessages(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(payloadExchangeState, sender,receiver)

        and {
            isPeerPair(sender, receiver),
            state.phase == MessagesReceived,
            not(state.messagesStored),
        }
    }

    /// Check whether acknowledgements may be determined for a received payload.
    ///
    /// - @param Node sender the node that sent the payload
    /// - @param Node receiver the node determining acknowledgements
    /// - @returns bool the computed result
    def canDetermineAck(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(payloadExchangeState, sender,receiver)

        and {
            isPeerPair(sender, receiver),
            state.phase == MessagesReceived,
            not(state.ackDetermined),
        }
    }

    /// Check whether the acknowledgement for a processed payload may be sent.
    ///
    /// - @param Node sender the original message sender
    /// - @param Node receiver the node sending the acknowledgement
    /// - @returns bool the computed result
    def canAckPayload(sender: Node, receiver: Node): bool = {
        val state = getPayloadExchangeState(payloadExchangeState, sender,receiver)

        and {
            isPeerPair(sender, receiver),
            state.phase == MessagesReceived,
            state.messagesStored,
            state.ackDetermined,
        }
    }

    /// Check whether the sender may receive the outstanding acknowledgement payload.
    ///
    /// - @param Node sender the original message sender
    /// - @param Node receiver the node returning the acknowledgement
    /// - @returns bool the computed result
    def canReceiveAckPayload(sender: Node, receiver: Node): bool = {
        and {
            isPeerPair(sender, receiver),
            getPayloadAcks(payloadState, sender, receiver).size() != 0,
            getPayloadExchangeState(payloadExchangeState, sender,receiver).phase == AckSent,
        }
    }

    /// Check whether the pair may enter or remain in the idle phase.
    ///
    /// - @param Node sender the sending node
    /// - @param Node receiver the receiving node
    /// - @returns bool the computed result
    def canIdle(sender: Node, receiver: Node): bool = {
        val phase = getPayloadExchangeState(payloadExchangeState, sender,receiver).phase

        and {
            isPeerPair(sender, receiver),
            (phase == Idle or phase == AckReceived),
        }
        
    }
    
    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    /// Initialise all protocol state with the configured node messages.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action init() = all {
        nodeState' = initNodeState(RANDOM_MESSAGE_IDS),
        payloadState' = initPayloadState,
        messageStore' = initMessageStore(RANDOM_MESSAGE_IDS),
        payloadExchangeState' = initPayloadExchangeState
    }

    /// Initialise all protocol state with the supplied node messages.
    ///
    /// - @param Node -> Set[MessageId] messageIds the initial message identifiers indexed by node
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action initWithMessageIds(messageIds) = all {
        nodeState' = initNodeState(messageIds),
        payloadState' = initPayloadState,
        messageStore' = initMessageStore(messageIds),
        payloadExchangeState' = initPayloadExchangeState
    }

    // ------------------------------------------------------------------------------------
    // STEP ACTIONS
    // ------------------------------------------------------------------------------------

    /// Perform one enabled protocol transition for a nondeterministically selected peer pair.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action step() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(
            n => n != sender
        ).oneOf()
        any {
            //TODO: add generate messages as step
            idle(sender, receiver),
            addOffers(sender, receiver),
            sendOffersPayload(sender, receiver),
            receiveOffersPayload(sender, receiver),
            determineRequests(sender, receiver),
            sendRequestsPayload(sender, receiver),
            receiveRequestsPayload(sender, receiver),
            addMessages(sender, receiver),
            sendMessagesPayload(sender, receiver),
            receiveMessagesPayload(sender, receiver),
            storeReceivedMessages(sender, receiver),
            determineAck(sender,receiver),
            sendAckPayload(sender, receiver),
            receiveAckPayload(sender, receiver),
        }
    }

    // ------------------------------------------------------------------------------------
    // PROCESS ACTIONS
    // ------------------------------------------------------------------------------------

    /// Reset an eligible peer pair to the idle exchange state without changing stored data.
    ///
    /// - @param Node sender the sending node
    /// - @param Node receiver the receiving node
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action idle(sender, receiver) = all {
        // Guards,
        canIdle(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            setPayloadExchangeState(
                payloadExchangeState, 
                sender, 
                receiver, 
                Idle,
                false,
                false,
            ),
    }

    /// Add the sender's pending offers to its payload for the receiver.
    ///
    /// - @param Node sender the node adding pending offers
    /// - @param Node receiver the destination peer
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action addOffers(sender, receiver) = all {
        // Guards
        canAddOffers(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                receiverPayload =>
                    match receiverPayload {
                        | None => Some({
                            payloadId: 0,
                            acks: Set(),
                            offers: getSetMessageIds(getNodeState(nodeState, sender, receiver).messages),
                            requests: Set(),
                            messages: Set()
                        })
                        | Some(payload) => Some({
                            ...payload,
                            offers: payload.offers.union(
                                getSetMessageIds(getNodeState(nodeState, sender, receiver).messages)
                            )
                        })
                    }
            )
        ),
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender,
                receiver,
                OffersAdded,
            ),
    }

    /// Mark the populated offer payload as sent to the receiver.
    ///
    /// - @param Node sender the node advertising messages
    /// - @param Node receiver the destination peer
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action sendOffersPayload(sender, receiver) = all {
        canSendOffersPayload(sender, receiver),
        messageStore' = messageStore,
        nodeState' = nodeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver,
                receiverState => {
                    ...receiverState,
                    offers: receiverState.offers.union(
                        getSetMessageIds(receiverState.messages).map(
                            id => { messageId: id, recordType: OfferRecord }
                        )
                    )
                }
            )
        ),
        payloadState' = payloadState,
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                OffersSent
            ),
    }

    /// Mark the in-flight offer payload as received by the peer.
    ///
    /// - @param Node sender the node advertising messages
    /// - @param Node receiver the node receiving the offers
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action receiveOffersPayload(sender, receiver) = all {
        canReceiveOffersPayload(sender, receiver),
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                OffersReceived,
            ),
    }

    /// Add requests for offered messages absent from the receiver's message store.
    ///
    /// - @param Node sender the node that supplied the offers
    /// - @param Node receiver the node selecting requests
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action determineRequests(sender, receiver) = all {
        canDetermineRequests(sender, receiver),
        messageStore' = messageStore,
        nodeState' =
            val requestIds = getPayloadOffers(payloadState, sender, receiver)
                .exclude(getSetMessageIds(getMessagesMessageStore(messageStore, receiver)))
            nodeState.setBy(
                receiver,
                receiverState => receiverState.setBy(
                    sender,
                    senderState => {
                        ...senderState,
                        requests: senderState.requests.union(
                            requestIds.map(id => { messageId: id, recordType: RequestRecord })
                        )
                    }
                )
            ),
        payloadState' =
            val requestIds = getPayloadOffers(payloadState, sender, receiver)
                .exclude(getSetMessageIds(getMessagesMessageStore(messageStore, receiver)))
            payloadState.setBy(
                sender,
                senderPayload => senderPayload.setBy(
                    receiver,
                    receiverPayload =>
                        match receiverPayload {
                            | Some(payload) => Some({ ...payload, requests: requestIds })
                            | None => None
                        }
                )
            ),
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                RequestAdded,
            ),
    }

    /// Mark the request payload as sent back to the offering node.
    ///
    /// - @param Node sender the node that supplied the offers
    /// - @param Node receiver the node returning requests
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action sendRequestsPayload(sender, receiver) = all {
        canSendRequestsPayload(sender, receiver),
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' =  
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                RequestSent,
            ),
    }

    /// Mark the in-flight request payload as received by the offering node.
    ///
    /// - @param Node sender the node receiving the requests
    /// - @param Node receiver the node that selected them
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action receiveRequestsPayload(sender, receiver) = all {
        canReceiveRequestsPayload(sender, receiver),
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                RequestReceived,
            ),
    }

    /// Add the sender's pending messages to its payload for the receiver.
    ///
    /// - @param Node sender the node adding pending messages
    /// - @param Node receiver the destination peer
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action addMessages(sender, receiver) = all {
        // Guards
        canAddMessages(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                receiverPayload =>
                    match receiverPayload {
                        | None => Some({
                            payloadId: 0,
                            acks: Set(),
                            offers: Set(),
                            requests: Set(),
                            messages: getNodeState(nodeState, sender, receiver).messages.filter(
                                message => message.messageId.in(getPayloadRequests(payloadState, sender, receiver))
                            )
                        })
                        | Some(payload) => Some({
                            ...payload,
                            messages: payload.messages.union(
                                getNodeState(nodeState, sender, receiver).messages.filter(
                                    message => message.messageId.in(payload.requests)
                                )
                            )
                        })
                    }
            )
        ),
        payloadExchangeState' =  
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                MessagesAdded,
            ),
    }

    /// Mark the sender's populated message payload as sent to the receiver.
    ///
    /// - @param Node sender the node sending the message payload
    /// - @param Node receiver the destination peer
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action sendMessagesPayload(sender, receiver) = all {
        // Guards
        canSendMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' =  
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                MessagesSent,
            ),
    }

    /// Mark an in-flight message payload as received by the receiver.
    ///
    /// - @param Node sender the node that sent the message payload
    /// - @param Node receiver the node receiving it
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action receiveMessagesPayload(sender, receiver) = all {
        // Guards
        canReceiveMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState.setBy(
            receiver,
            receiverState => receiverState.setBy(
                sender,
                senderState => {
                    ...senderState,
                    requests: senderState.requests.filter(
                        request => not(
                            request.messageId.in(
                                getSetMessageIds(getPayloadMessages(payloadState, sender, receiver))
                            )
                        )
                    )
                }
            )
        ),
        payloadState' = payloadState,
        payloadExchangeState' =  
            setPayloadExchangeStatePhase(
                payloadExchangeState, 
                sender, 
                receiver, 
                MessagesReceived,
            ),
    }

    /// Store received messages and update the receiver's knowledge of the sender.
    ///
    /// - @param Node sender the node that sent the messages
    /// - @param Node receiver the node storing them
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action storeReceivedMessages(sender, receiver) = all {
        // Guards
        canStoreReceivedMessages(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore.setBy(
            receiver,
            // With the use of union no previous messages can be removed, thus proving monotonicity.
            receiverStore => receiverStore.union(
                getPayloadMessages(payloadState, sender, receiver)
            )
        ),
        nodeState' = nodeState.setBy(
            receiver,
            receiverState => receiverState.setBy(
                sender,
                senderState => {
                    ...senderState,
                    messages: excludeMessagesById(
                        senderState.messages,
                        getSetMessageIds(getPayloadMessages(payloadState, sender, receiver))
                    )
                }
            )
        ),
        payloadState' = payloadState,
        payloadExchangeState' = 
            setPayloadExchangeStateMessagesStored(
                payloadExchangeState,
                sender,
                receiver,
                true,
            ),
    }

    /// Determine acknowledgement identifiers for all messages in a received payload.
    ///
    /// - @param Node sender the original message sender
    /// - @param Node receiver the node determining acknowledgements
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action determineAck(sender, receiver) = all {
        // Guards
        canDetermineAck(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                // Reuse the sender payload to prevent conflicting payload states.
                receiverPayload =>
                    match receiverPayload {
                        | Some(payload) => Some({
                            ...payload,
                            // Acknowledge every message received from the sender.
                            acks: getSetMessageIds(payload.messages)
                        })
                        | None => None
                    }
            )
        ),
        payloadExchangeState' = 
            setPayloadExchangeStateAckDetermined(
                payloadExchangeState,
                sender,
                receiver,
                true,
            ),
    }

    /// Mark a determined acknowledgement payload as sent.
    ///
    /// - @param Node sender the original message sender
    /// - @param Node receiver the node sending the acknowledgement
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action sendAckPayload(sender, receiver) = all {
        // Guards
        canAckPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState,
                sender, 
                receiver, 
                AckSent,
            ),
    }


    /// Receive acknowledgements and remove acknowledged messages from pending state and payload.
    /// With retransmission, the sender can now check with the offers and the acks if everything 
    /// has been delivered or resend specific messages.
    ///
    /// - @param Node sender the node receiving the acknowledgement
    /// - @param Node receiver the node that produced it
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action receiveAckPayload(sender, receiver) = all {
        // Guards
        canReceiveAckPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = 
            val ackIds = getPayloadAcks(payloadState, sender, receiver)

            nodeState.setBy(
                sender,
                senderState => senderState.setBy(
                    receiver,
                    receiverState => {
                        ...receiverState,
                        // Remove the acknowledged messages from the sender's node state for the receiver, as they have been acknowledged by the receiver.
                        messages: excludeMessagesById(receiverState.messages, ackIds)
                    }
                )
            ),
        payloadState' = 
            val ackIds = getPayloadAcks(payloadState, sender, receiver)
            
            payloadState.setBy(
                sender,
                senderPayload => senderPayload.setBy(
                    receiver,
                    // Remove acknowledged messages and represent a fully consumed payload as absent.
                    receiverPayload =>
                        match receiverPayload {
                            | Some(payload) =>
                                val remainingMessages = excludeMessagesById(payload.messages, ackIds)
                                if (remainingMessages.size() == 0) {
                                    None
                                } else {
                                    Some({
                                        ...payload,
                                        acks: Set(),
                                        messages: remainingMessages
                                    })
                                }
                            | None => None
                        }
                )
            ),
        payloadExchangeState' = 
            setPayloadExchangeStatePhase(
                payloadExchangeState,
                sender, 
                receiver, 
                AckReceived,
            ),
    }

    // ------------------------------------------------------------------------------------
    // HELPER VERIFICATION ACTIONS
    // ------------------------------------------------------------------------------------

    /// Receive an eligible message payload for some nondeterministically chosen peer pair.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action someReceiveMessagesPayload() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        receiveMessagesPayload(sender, receiver)
    }

    /// Determine acknowledgements for some nondeterministically chosen peer pair.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action someDetermineAck() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        determineAck(sender, receiver)
    }

    /// Receive an acknowledgement for some nondeterministically chosen peer pair.
    ///
    /// - @returns bool whether the action is enabled and its transition constraints hold
    action someReceiveAckPayload() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(n => n != sender).oneOf()
        receiveAckPayload(sender, receiver)
    }

    // -------------------------------------------------------------------------------------
    // SAFETY PROPOSITIONS
    // -------------------------------------------------------------------------------------

    /// Assert that every node's synchronisation state for itself remains empty.
    ///
    /// - @returns bool whether the proposition holds
    val self_nodeState_is_always_empty =
        self_nodeState_is_always_empty_predicate(NODES, nodeState)

    /// Assert that every node's payload addressed to itself remains empty.
    ///
    /// - @returns bool whether the proposition holds
    val self_payloadState_is_always_empty =
        self_payloadState_is_always_empty_predicate(NODES, payloadState)

    /// Assert that the unused reverse-direction payload remains empty during an exchange.
    ///
    /// - @returns bool whether the proposition holds
    val reverse_payloadState_is_always_empty =
        reverse_payloadState_is_always_empty_predicate(
            NODES,
            payloadState,
            payloadExchangeState
        )
    
    /// Assert that every node's exchange state with itself remains at its default.
    ///
    /// - @returns bool whether the proposition holds
    val self_payloadExchangeState_is_always_empty =
        self_payloadExchangeState_is_always_empty_predicate(
            NODES,
            payloadExchangeState
        )

    /// Assert that every payload message is pending or already known by the receiver.
    ///
    /// - @returns bool whether the proposition holds
    val payload_messages_are_pending_or_known_by_receiver =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getPayloadMessages(payloadState, sender, receiver).forall(
                        m =>
                            // Still scheduled for this receiver
                            m.in(getNodeState(nodeState, sender, receiver).messages)
                            or 
                            // No longer scheduled because the receiver already has it
                            m.in(getMessagesMessageStore(messageStore, receiver))
                    )
            )
        )

    /// Assert that every payload message exists in the sender's message store.
    ///
    /// - @returns bool whether the proposition holds
    val payload_messages_belong_to_sender =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getPayloadMessages(payloadState, sender, receiver).forall(
                        m => m.in(getMessagesMessageStore(messageStore, sender))
                    )
            )
        )

    /// Combine the payload-message ownership and receiver-knowledge safety properties.
    ///
    /// - @returns bool whether the proposition holds
    val payload_message_invariant = 
        and {
            payload_messages_are_pending_or_known_by_receiver,
            payload_messages_belong_to_sender,
            pending_messages_belong_to_sender,
        }

    /// Assert that every message pending for a receiver belongs to the sender.
    ///
    /// - @returns bool whether the proposition holds
    val pending_messages_belong_to_sender =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                    getNodeState(nodeState, sender, receiver).messages.forall(
                        m => m.in(getMessagesMessageStore(messageStore, sender))
                    )
            )
        )

    /// Assert that acknowledgement identifiers refer to messages in the same payload.
    ///
    /// - @returns bool whether the proposition holds
    val ack_ids_match_payload_messages =
        NODES.forall(
            sender => NODES.forall(
                receiver => getPayloadAcks(payloadState, sender, receiver).forall(
                    id => id.in(payloadMessageIds(getPayload(payloadState, sender, receiver)))
                )
            )
        )

    /// Assert that sent acknowledgement identifiers refer to messages stored by the receiver.
    ///
    /// - @returns bool whether the proposition holds
    val sent_ack_ids_match_stored_messages  =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == AckSent
                        implies
                        getPayloadAcks(payloadState, sender, receiver).forall(
                            id => id.in(
                                getSetMessageIds(messageStore.get(receiver))
                            )
                        )
                    )
            )
        )
    
    /// Combine the acknowledgement soundness safety properties.
    ///
    /// - @returns bool whether the proposition holds
    val sent_acks_are_sound = 
        and {
            sent_ack_ids_match_stored_messages,
            ack_ids_match_payload_messages,
            pending_acks_imply_nonempty_payload,
        }

    /// Assert that a nonempty acknowledgement set implies a nonempty message payload.
    ///
    /// - @returns bool whether the proposition holds
    val pending_acks_imply_nonempty_payload =
        NODES.forall(
            sender => NODES.forall(
                receiver => getPayloadAcks(payloadState, sender, receiver).size() > 0
                    implies getPayloadMessages(payloadState, sender, receiver).size() > 0
            )
        )
    
    /// Assert that a determined acknowledgement covers exactly the payload's messages.
    ///
    /// - @returns bool whether the proposition holds
    val determined_ack_covers_payload =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).ackDetermined
                        implies
                        getPayloadAcks(payloadState, sender, receiver)
                            == payloadMessageIds(getPayload(payloadState, sender, receiver))
                    )
            )
        )

    /// Assert that the idle phase has neither stored-message nor determined-ack flags set.
    ///
    /// - @returns bool whether the proposition holds
    val when_idle_not_messageStored_and_not_ackDetermined =
        NODES.forall(
            sender => NODES.forall(
                receiver => 
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == Idle
                        implies
                        and {
                            not(getPayloadExchangeState(payloadExchangeState, sender, receiver).messagesStored),
                            not(getPayloadExchangeState(payloadExchangeState, sender, receiver).ackDetermined)
                        }
                    )
            )
        )

    /// Assert that the MessagesAdded phase always has a nonempty message payload.
    ///
    /// - @returns bool whether the proposition holds
    val when_MessagesAdded_payload_messages_non_empty =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == MessagesAdded
                        implies
                        getPayloadMessages(payloadState, sender, receiver).size() > 0
                    )
            )
        )

    /// Assert that the MessagesSent phase always has a nonempty message payload.
    ///
    /// - @returns bool whether the proposition holds
    val when_MessagesSent_payload_messages_non_empty =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == MessagesSent
                        implies
                        getPayloadMessages(payloadState, sender, receiver).size() > 0
                    )
            )
        )

    /// Assert that AckSent follows storage and acknowledgement determination with nonempty acknowledgements.
    ///
    /// - @returns bool whether the proposition holds
    val when_AckSent_messagesStored_ackDetermined_acks_non_empty =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == AckSent
                        implies
                        and {
                            getPayloadExchangeState(payloadExchangeState, sender, receiver).messagesStored,
                            getPayloadExchangeState(payloadExchangeState, sender, receiver).ackDetermined,
                            getPayloadAcks(payloadState, sender, receiver).size() > 0
                        }
                    )
            )
        )

    /// Assert that acknowledgement receipt leaves the acknowledgement set empty.
    ///
    /// - @returns bool whether the proposition holds
    val when_AckReceived_acks_empty = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == AckReceived
                        implies
                        getPayloadAcks(payloadState, sender, receiver).size() == 0
                    )
            )
        )

    /// Assert that acknowledgement determination occurs only in compatible exchange phases.
    ///
    /// - @returns bool whether the proposition holds
    val when_ackDetermined = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).ackDetermined
                        implies
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase.in(Set(MessagesReceived, AckSent, AckReceived))
                    )
            )
        )

    /// Assert that received-message storage occurs only in compatible exchange phases.
    ///
    /// - @returns bool whether the proposition holds
    val when_messagesStored = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).messagesStored
                        implies
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase.in(Set(MessagesReceived, AckSent, AckReceived))
                    )
            )
        )

    // -------------------------------------------------------------------------------------
    // FAIRNESS PROPOSITIONS
    // -------------------------------------------------------------------------------------

    /// Require weak fairness for receiving some sent message payload.
    ///
    /// - @returns bool whether the proposition holds
    temporal receive_messages_payload_fairness =
        someReceiveMessagesPayload.weakFair(Set(payloadExchangeState))

    /// Require weak fairness for determining some payload acknowledgement.
    ///
    /// - @returns bool whether the proposition holds
    temporal determine_ack_fairness =
        someDetermineAck.weakFair(Set(payloadState))

    /// Require weak fairness for receiving some acknowledgement payload.
    ///
    /// - @returns bool whether the proposition holds
    temporal receive_ack_payload_fairness =
        someReceiveAckPayload.weakFair(Set(nodeState))

    /// Define fairness for the complete delivery, acknowledgement, and idle protocol cycle.
    ///
    /// - @returns bool whether the proposition holds
    temporal protocol_fairness =
        delivery_fairness
        and acknowledgement_fairness
        and NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies
                        idle(sender, receiver)
                            .weakFair(Set(payloadExchangeState))
            )
        )

    /// Define weak fairness for every message-delivery action and peer pair.
    ///
    /// - @returns bool whether the proposition holds
    temporal delivery_fairness =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        and {
                            addMessages(sender, receiver).weakFair(Set(payloadExchangeState)),
                            sendMessagesPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                            receiveMessagesPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                            storeReceivedMessages(sender, receiver).weakFair(Set(payloadExchangeState)),
                        }
                    )
            )
        )

    /// Define weak fairness for every acknowledgement action and peer pair.
    ///
    /// - @returns bool whether the proposition holds
    temporal acknowledgement_fairness =
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    isPeerPair(sender, receiver) implies (
                        and {
                            determineAck(sender, receiver).weakFair(Set(payloadExchangeState)),
                            sendAckPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                            receiveAckPayload(sender, receiver).weakFair(Set(payloadExchangeState)),
                        }
                    )
            )
        )

    // -------------------------------------------------------------------------------------
    // LIVENESS PROPOSITIONS
    // -------------------------------------------------------------------------------------

    /// Ensure each node's message store never loses previously stored messages.
    ///
    /// NOT CONVERTABLE TO TLA+
    /// This proposition produces error:
    ///     [] followed by action not of form [A]_v
    /// Therefore it can't be used
    ///
    /// - @returns bool whether the proposition holds
    // temporal messageStores_are_monotonic = 
    //     always(
    //         NODES.forall(
    //             n => messageStore.get(n).subseteq(
    //                 next(messageStore.get(n))
    //             )
    //         )
    //     )
    /// Assert that every in-flight payload is eventually received under receive fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal in_flight_payload_is_eventually_received =
        receive_messages_payload_fairness implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        hasInFlightPayload(getPayloadExchangeState(payloadExchangeState, sender, receiver))
                        leadsTo getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == MessagesReceived
                )
            )
        )

    /// Assert that every sent payload is eventually acknowledged under delivery fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal pending_payload_is_eventually_acknowledged =
        (receive_messages_payload_fairness and determine_ack_fairness) implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        and {
                            getPayloadMessages(payloadState, sender, receiver).size() > 0,
                            getPayloadExchangeState(payloadExchangeState, sender,receiver).phase == MessagesSent,
                        }
                        leadsTo getPayloadAcks(payloadState, sender, receiver).size() > 0
                )
            )
        )

    /// Assert that every pending acknowledgement is eventually cleared under delivery and acknowledgement fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal pending_ack_is_eventually_cleared =
        (delivery_fairness and acknowledgement_fairness) implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        getPayloadAcks(payloadState, sender, receiver).size() > 0
                        leadsTo getPayloadAcks(payloadState, sender, receiver).size() == 0
                )
            )
        )

    /// Ensure a pending message ID is removed only after the receiver stores the message.
    ///
    /// Not liveness, but temporal safety property
    /// NOT CONVERTABLE TO TLA+
    /// This proposition produces error:
    ///     [] followed by action not of form [A]_v
    /// Therefore it can't be used
    ///
    /// - @returns bool whether the proposition holds
    // temporal pending_message_id_removed_only_after_storage =
    //     NODES.forall(
    //         sender => NODES.forall(
    //             receiver =>
    //                 isPeerPair(sender, receiver) implies
    //                 MESSAGES.keys().forall(
    //                     id =>
    //                         always(
    //                             (
    //                                 id.in(
    //                                     getSetMessageIds(
    //                                         getNodeState(nodeState, sender, receiver).messages
    //                                     )
    //                                 )
    //                                 and next(
    //                                     not(
    //                                         id.in(
    //                                             getSetMessageIds(
    //                                                 getNodeState(nodeState, sender, receiver).messages
    //                                             )
    //                                         )
    //                                     )
    //                                 )
    //                             )
    //                             implies next(
    //                                 id.in(
    //                                     getSetMessageIds(
    //                                         getMessagesMessageStore(messageStore, receiver)
    //                                     )
    //                                 )
    //                             )
    //                         )
    //                 )
    //         )
    //     )

    /// Assert that acknowledged messages are eventually removed under delivery and acknowledgement fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal acknowledged_messages_are_eventually_removed =
        (delivery_fairness and acknowledgement_fairness) implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver =>
                        isPeerPair(sender, receiver) implies
                        MESSAGES.keys().forall(
                            id =>
                                id.in(getPayloadAcks(payloadState, sender, receiver))
                                leadsTo (
                                    not(
                                        id.in(
                                            getSetMessageIds(
                                                getNodeState(nodeState, sender, receiver).messages
                                            )
                                        )
                                    )
                                    and not(
                                        id.in(
                                            payloadMessageIds(getPayload(payloadState, sender, receiver))
                                        )
                                    )
                                )
                        )
                )
            )
        )

    /// Assert that pending messages eventually reach the receiver under delivery fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal pending_messages_are_eventually_delivered =
        delivery_fairness implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver =>
                        isPeerPair(sender, receiver) implies
                        MESSAGES.keys().forall(
                            id =>
                                id.in(
                                    getSetMessageIds(
                                        getNodeState(nodeState, sender, receiver).messages
                                    )
                                )
                                leadsTo id.in(
                                    getSetMessageIds(
                                        getMessagesMessageStore(messageStore, receiver)
                                    )
                                )
                        )
                )
            )
        )

    /// Assert that pending messages eventually leave sender state under protocol fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal pending_messages_are_eventually_cleared =
        protocol_fairness implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver =>
                        isPeerPair(sender, receiver) implies
                        MESSAGES.keys().forall(
                            id =>
                                id.in(
                                    getSetMessageIds(
                                        getNodeState(nodeState, sender, receiver).messages
                                    )
                                )
                                leadsTo not(
                                    id.in(
                                        getSetMessageIds(
                                            getNodeState(nodeState, sender, receiver).messages
                                        )
                                    )
                                )
                        )
                )
            )
        )

    /// Ensure changes to one exchange direction leave the reverse payload unchanged.
    ///
    /// NOT CONVERTABLE TO TLA+
    /// This proposition produces error:
    ///     [] followed by action not of form [A]_v
    ///
    /// - @returns bool whether the proposition holds
    // temporal reverse_payload_is_unchanged =
    //     always(
    //         NODES.forall(
    //             sender => NODES.forall(
    //                 receiver =>
    //                     isPeerPair(sender, receiver) implies (
    //                         (
    //                             next(
    //                                 getPayloadExchangeState(payloadExchangeState, sender, receiver)
    //                             )
    //                             != getPayloadExchangeState(payloadExchangeState, sender, receiver)
    //                             or
    //                             next(
    //                                 getPayload(payloadState, sender, receiver)
    //                             )
    //                             != getPayload(payloadState, sender, receiver)
    //                         )
    //                         implies
    //                         next(
    //                             getPayload(payloadState, receiver, sender)
    //                         )
    //                         == getPayload(payloadState, receiver, sender)
    //                     )
    //             )
    //         )
    //     )

    // -------------------------------------------------------------------------------------
    // WITNESS-STYLE PROPOSITIONS (NON-INVARIANTS)
    // -------------------------------------------------------------------------------------
    /* > start witness with 'can_' for quint runner */

    /// Witness that a reachable state may contain messages pending for a peer.
    ///
    /// - @returns bool whether the proposition holds
    val can_have_pending_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getNodeState(nodeState, sender,receiver).messages.size() > 0,
                    }
            )
        )

    /// Witness that a reachable state may contain messages in a payload.
    ///
    /// - @returns bool whether the proposition holds
    val can_have_payload_messages =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getPayloadMessages(payloadState, sender, receiver).size() > 0,
                    }
            )
        )

    /// Witness that a reachable state may contain an in-flight payload.
    ///
    /// - @returns bool whether the proposition holds
    val can_have_in_flight_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        hasInFlightPayload(getPayloadExchangeState(payloadExchangeState, sender, receiver)),
                    }
            )
        )

    /// Witness that a reachable state may contain pending acknowledgements.
    ///
    /// - @returns bool whether the proposition holds
    val can_have_pending_acks =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getPayloadAcks(payloadState, sender, receiver).size() > 0,
                    }
            )
        )

    /// Witness that a reachable state may contain a delivered payload.
    ///
    /// - @returns bool whether the proposition holds
    val can_have_delivered_payload =
        NODES.exists(
            sender => NODES.exists(
                receiver => 
                    and {
                        isPeerPair(sender, receiver),
                        getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == MessagesReceived,
                    }
            )
        )
}
