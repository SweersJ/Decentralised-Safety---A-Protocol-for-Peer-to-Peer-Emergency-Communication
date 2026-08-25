/// Model the configurable batch message synchronisation and acknowledgement protocol.
///
/// - @param Set[Node] NODES the protocol participants included in the model
/// - @param Node -> Set[MessageId] RANDOM_MESSAGE_IDS the initial message identifiers assigned to each node
/// - @returns batch the protocol module
module batch {
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
    import record_state.* from "./../#global/types/record_state"
    // > Messages
    import messages.* from "./../#global/messages/messages"
    // > Helper functions
    import init_helpers(INIT_NODES = NODES).* from "./../#global/helper-functions/init"
    import guard_helpers.* from "./../#global/helper-functions/guards"
    import getter_helpers.* from "./../#global/helper-functions/getters"
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
            getPayloadExchangeState(payloadExchangeState, sender,receiver).phase == Idle,
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

    // > SETTER FUNCTIONS

    /// Return the exchange-state map with one sender-receiver entry replaced.
    ///
    /// - @param Node sender the sender entry to update
    /// - @param Node receiver the receiver entry to update
    /// - @param PayloadExchangePhase newPayloadExchangePhase the replacement exchange phase
    /// - @param bool newMessagesStored whether received messages have been stored
    /// - @param bool newAckDetermined whether acknowledgements have been determined
    /// - @returns Node -> (Node -> PayloadExchangeState) the computed result
    def setPayloadExchangeState(
        sender: Node,
        receiver: Node,
        newPayloadExchangePhase: PayloadExchangePhase,
        newMessagesStored: bool,
        newAckDetermined: bool
    ): Node -> (Node -> PayloadExchangeState) = {
        payloadExchangeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver,
                receiverState => {
                    phase: newPayloadExchangePhase,
                    messagesStored: newMessagesStored,
                    ackDetermined: newAckDetermined
                }
            )
        )
    }

    // > GENERAL FUNCTIONS

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
        payloadExchangeState' = setPayloadExchangeState(
            sender,
            receiver,
            Idle,
            false,
            false
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
                            offers: Set(),
                            requests: Set(),
                            acks: Set(),
                            messages: getNodeState(nodeState, sender, receiver).messages
                        })
                        | Some(payload) => Some({
                            ...payload,
                            // Keep any messages already present when extending an existing payload.
                            messages: payload.messages.union(
                                getNodeState(nodeState, sender, receiver).messages
                            )
                        })
                    }
            )
        ),
        payloadExchangeState' =
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender, receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                MessagesAdded,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
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
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender,receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                MessagesSent,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
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
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadExchangeState' =
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender,receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                MessagesReceived,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
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
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender,receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                currentPayloadExchangeState.phase,
                true,
                currentPayloadExchangeState.ackDetermined
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
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender,receiver)

            setPayloadExchangeState(
                sender,
                receiver,
                currentPayloadExchangeState.phase,
                currentPayloadExchangeState.messagesStored,
                true
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
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender,receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                AckSent,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
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
            val currentPayloadExchangeState = getPayloadExchangeState(payloadExchangeState, sender,receiver)
            setPayloadExchangeState(
                sender,
                receiver,
                AckReceived,
                currentPayloadExchangeState.messagesStored,
                currentPayloadExchangeState.ackDetermined
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

    /// Require weak fairness for receiving some sent message payload.
    ///
    /// - @returns bool whether the proposition holds
    temporal fair_receive_messages_payload =
        someReceiveMessagesPayload.weakFair(Set(payloadExchangeState))

    /// Require weak fairness for determining some payload acknowledgement.
    ///
    /// - @returns bool whether the proposition holds
    temporal fair_determine_ack =
        someDetermineAck.weakFair(Set(payloadState))

    /// Require weak fairness for receiving some acknowledgement payload.
    ///
    /// - @returns bool whether the proposition holds
    temporal fair_receive_ack_payload =
        someReceiveAckPayload.weakFair(Set(nodeState))

    /// Assert that every in-flight payload is eventually received under receive fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal in_flight_payload_is_eventually_received =
        fair_receive_messages_payload implies (
            NODES.forall(
                sender => NODES.forall(
                    receiver => isPeerPair(sender, receiver) implies
                        hasInFlightMessagesPayload(getPayloadExchangeState(payloadExchangeState, sender, receiver))
                        leadsTo getPayloadExchangeState(payloadExchangeState, sender, receiver).phase == MessagesReceived
                )
            )
        )

    /// Assert that every sent payload is eventually acknowledged under delivery fairness.
    ///
    /// - @returns bool whether the proposition holds
    temporal pending_payload_is_eventually_acknowledged =
        (fair_receive_messages_payload and fair_determine_ack) implies (
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
                        hasInFlightMessagesPayload(getPayloadExchangeState(payloadExchangeState, sender, receiver)),
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
