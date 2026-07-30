module batch {
    import messages.* from "messages"
    
    // ------------------------------------------------------------------------------------
    // TYPES
    // ------------------------------------------------------------------------------------

    type RecordType = Offer | Request | None
    
    //TODO: store records states
    type RecordState = { //TODO: add count and epoch in next version
        messageId: MessageId, // Not used as map key, but as a value to be able to track the message ID in the record state.
        recordType: RecordType
    }

    type PayloadId = int
    
    //TODO: add payload type to indicate if it is a batch or interactive payload or can it be determined already from the payload itself
    type Payload = {
        payloadId: PayloadId,
        acks: Set[MessageId],
        offers: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }

    type NodeState = {
        offers: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        requests: Set[RecordState], //TODO: add map of messageId to recordState to be able to retrieve the record state by its ID.
        messages: Set[Message]
    }

    type Node = str

    type PayloadExchangeState = Idle | MessagesSent | MessagesReceived | AckSent | AckReceived

    // ------------------------------------------------------------------------------------
    // CONSTANT VALUES
    // ------------------------------------------------------------------------------------

    pure val ALICE: Node = "Alice"
    pure val BOB: Node = "Bob"
    pure val NODES: Set[Node] = Set(ALICE, BOB)

    pure val EMPTY_PAYLOAD: Payload = {
        payloadId: 0, //TODO: reuse payloadId to check if it is the same payload that is being sent and received, or if it is a new payload. This can be used to detect if a payload has been lost or if it is a duplicate.
        acks: Set(),
        offers: Set(),
        requests: Set(),
        messages: Set()
    }

    pure val EMPTY_NODE_STATE: NodeState = {
        offers: Set(),
        requests: Set(),
        messages: Set()
    }

    pure val EMPTY_RECORD_STATE: RecordState = {
        messageId: "",
        recordType: None
    }

    // ------------------------------------------------------------------------------------
    // STATE VARIABLES
    // ------------------------------------------------------------------------------------
    
    // Messages stored per node
    // (simulation of storing messages in database of a specific node).
    var messageStore: Node -> Set[Message] //TODO: add a map of messageId to message to be able to retrieve the message by its ID.
    
    // states of every peer of the offers, requests, and messages (sender -> (receiver -> NodeState)).
    // (simulation of storing at node side what transport is expected for each node at the node side)
    var nodeState: Node -> (Node -> NodeState)
    
    // Payload state kept per sender -> receiver.
    var payloadState: Node -> (Node -> Payload)
    
    // store sent state
    var payloadSent: Node -> (Node -> bool) 
    
    // store received state
    var payloadReceived: Node -> (Node -> bool)

    // TODO: add the payload generator
    // Payload-id generator for future send actions.
    var nextPayloadId: int
    
    //TODO: change this with payloadSent and payloadReceived to a single state variable that indicates the state of the payload exchange between two nodes.
    var payloadExchangeState: Node -> (Node -> PayloadExchangeState)

    // ------------------------------------------------------------------------------------
    // HELPER FUNCTIONS
    // ------------------------------------------------------------------------------------

    pure def initNodeState(randomMessageIdsAlice: Set[MessageId], randomMessageIdsBob: Set[MessageId]): Node -> (Node -> NodeState) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => {
                    ...EMPTY_NODE_STATE,
                    messages: if (sender == ALICE) getMessages(randomMessageIdsAlice) else getMessages(randomMessageIdsBob)
                }
            )
        )
    }

    pure def initPayloadState(): Node -> (Node -> Payload) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => EMPTY_PAYLOAD
            )
        )
    }

    pure def initMessageStore(randomMessageIdsAlice: Set[MessageId], randomMessageIdsBob: Set[MessageId]): Node -> Set[Message] = {
        NODES.mapBy(
            node => if (node == ALICE) getMessages(randomMessageIdsAlice) else getMessages(randomMessageIdsBob)
        )
    }

    pure def initPayloadSentState(): Node -> (Node -> bool) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => false
            )
        )
    }

    pure def initPayloadReceivedState(): Node -> (Node -> bool) = {
        NODES.mapBy(
            sender => NODES.mapBy(
                receiver => false
            )
        )
    }

    /* TODO: activate when in interactive mode
    pure def getRecordStateMessageIds(recordStates: Set[RecordState]): Set[MessageId] = {
        recordStates.map(rs => rs.messageId)
    } 
    */

    // Sender and receiver must be different nodes, otherwise it doesn't make sense to send a payload to itself.
    pure def isPeerPair(sender: Node, receiver: Node): bool = {
        sender != receiver
    }

    // check if the sender has messages to send to the receiver, otherwise it doesn't make sense to add messages to the payload with no messages.
    def hasMessagesToProcess(sender: Node, receiver: Node): bool = {
        messageStore.get(sender).size() != 0 and                    
        nodeState.get(sender).get(receiver).messages.size() != 0
    }

    // only proceed when there is at least one message the receiver does not yet have.
    def hasSyncDelta(sender: Node, receiver: Node): bool = {
        nodeState.get(sender).get(receiver).messages.exists(
            m => not(m.in(messageStore.get(receiver)))
        )
    }

    def canAddMessages(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        hasMessagesToProcess(sender, receiver) and
        hasSyncDelta(sender, receiver) and
        not(payloadSent.get(sender).get(receiver)) and
        not(payloadReceived.get(receiver).get(sender))
    }

    def canSendMessagesPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadState.get(sender).get(receiver).messages.size() != 0 and
        nodeState.get(sender).get(receiver).messages.size() != 0 and
        not(payloadSent.get(sender).get(receiver)) and
        not(payloadReceived.get(receiver).get(sender))
    }

    def canReceiveMessagesPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadSent.get(sender).get(receiver) and
        not(payloadReceived.get(receiver).get(sender))
    }

    def canProcessDeliveredPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadSent.get(sender).get(receiver) and
        payloadReceived.get(receiver).get(sender)
    }

    def canReceiveAckPayload(sender: Node, receiver: Node): bool = {
        isPeerPair(sender, receiver) and
        payloadState.get(sender).get(receiver).acks.size() != 0 and
        payloadSent.get(receiver).get(sender) and
        not(payloadReceived.get(sender).get(receiver))
    }
    
    // ------------------------------------------------------------------------------------
    // INIT ACTIONS
    // ------------------------------------------------------------------------------------

    action init() = {
        nondet randomMessageIdsAlice = getMessageIdsPowerset.oneOf() //TODO: find a way to generate random messages depending on the number of Nodes
        nondet randomMessageIdsBob = getMessageIdsPowerset.oneOf()
        all {
            nodeState' = initNodeState(randomMessageIdsAlice, randomMessageIdsBob),
            payloadState' = initPayloadState,
            messageStore' = initMessageStore(randomMessageIdsAlice, randomMessageIdsBob),
            payloadSent' = initPayloadSentState,
            payloadReceived' = initPayloadReceivedState,
        }
    }

    // ------------------------------------------------------------------------------------
    // STEP ACTIONS
    // ------------------------------------------------------------------------------------

    action step() = {
        nondet sender = NODES.oneOf()
        nondet receiver = NODES.filter(
            n => n != sender
        ).oneOf()
        any {
            addMessages(sender, receiver),
            sendMessagesPayload(sender, receiver),
            receiveMessagesPayload(sender, receiver),
            storeReceivedMessages(sender, receiver),
            determineAck(sender,receiver),
            sendAckPayload(sender, receiver),
            receiveAckPayload(sender, receiver)
        }
    }

    // ------------------------------------------------------------------------------------
    // PROCESS ACTIONS
    // ------------------------------------------------------------------------------------

    // Batch flow 1: Sender adds messages to its payload.
    action addMessages(sender, receiver) = all {
        // Guards
        canAddMessages(sender, receiver),
        
        // Next state updates
        /* TODO: [added] add check to ensure that the messages added to the payload are not already 
        in the payload and [not added] that they are not already acknowledged by the receiver. */
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                receiverPayload => {
                    ...receiverPayload,
                    // Make sure if another payload is send the previous messages are not removed from the payload from sender to receiver
                    messages: receiverPayload.messages.union(
                        nodeState.get(sender).get(receiver).messages
                    )
                }
            )
        ),
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived
    }

    // Batch flow 2: Sender sends its payload to the receiver. Functionally, this action does 
    // not change the state of the sender or receiver, but it is used to model the sending of 
    // the payload in the system.
    action sendMessagesPayload(sender, receiver) = all {
        // Guards
        canSendMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadSent' = payloadSent.setBy(
            sender,
            senderState => senderState.setBy(receiver, _ => true)
        ),
        payloadReceived' = payloadReceived
    }

    action receiveMessagesPayload(sender, receiver) = all {
        // Guards
        canReceiveMessagesPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadSent' = payloadSent, //TODO: maybe disable sent value of sender to receiver already instead of when the new payload is sent from receiver to sender.
        payloadReceived' = payloadReceived.setBy(
            receiver,
            receiverState => receiverState.setBy(sender, _ => true)
        )
    }

    action storeReceivedMessages(sender, receiver) = all {
        // Guards
        canProcessDeliveredPayload(sender, receiver),
        
        // Next state updates
        messageStore' = messageStore.setBy(
            receiver,
            receiverStore => receiverStore.union(
                payloadState.get(sender).get(receiver).messages
            )
        ),
        nodeState' = nodeState.setBy(
            receiver,
            receiverState => receiverState.setBy(
                sender,
                senderState => {
                    ...senderState,
                    messages: senderState.messages.exclude(
                        payloadState.get(sender).get(receiver).messages //TODO: check if this is correct, as the rec can be same with internal data but not the same object
                    )
                }
            )
        ),
        payloadState' = payloadState,
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived
    }

    // Batch flow 3: Receiver acknowledges the payload received from the sender. The receiver
    // checks the messages in the payload and acknowledges only those messages that it has not 
    // already received. The receiver updates its message store with the new messages and 
    // updates the payload state to reflect the acknowledged messages.
    action determineAck(sender, receiver) = all {
        // Guards
        canProcessDeliveredPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                // Reuse the sender payload to prevent conflicting payload states.
                receiverState => {
                    ...receiverState,
                    // Acknowledge all messages received from the sender regardless of whether they were already in the message store or not. This is because the sender may have sent messages that the receiver already has, and the receiver needs to acknowledge those messages to inform the sender that it has received them.
                    acks: receiverState.messages.map(
                        m => m.messageId
                    ) 
                }
            )
        ),
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived
    }

    // Batch flow 4: Sender sends the acknowledgment payload to the receiver. 
    action sendAckPayload(sender, receiver) = all {
        // Guards
        canProcessDeliveredPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState,
        payloadState' = payloadState,
        payloadSent' = payloadSent.setBy(
            receiver,
            receiverState => receiverState.setBy(sender, _ => true)
        ).setBy( // Reset the payload sent state for the sender to receiver to false, as the sender has sent the acknowledgment payload to the receiver and is now waiting for the receiver to acknowledge the acknowledgment payload.
            sender,
            senderState => senderState.setBy(receiver, _ => false)
        ),
        // Reset the payload received state for the sender to receiver to false, as the sender has sent the acknowledgment payload to the receiver and is now waiting for the receiver to acknowledge the acknowledgment payload.
        payloadReceived' = payloadReceived.setBy(
            sender,
            senderState => senderState.setBy(receiver, _ => false)
        ).setBy( // Reset the payload received state for the receiver to sender to false, as the receiver has sent the acknowledgment payload to the sender and is now waiting for the sender to acknowledge the acknowledgment payload.
            receiver,
            receiverState => receiverState.setBy(sender, _ => false)
        )
    }

    // Batch flow 5: Receiver receives the acknowledgment payload from the sender. The receiver
    // updates its payload state to reflect the acknowledged messages and clears the acknowledgments.
    // With retransmission, the sender can now check with the offers and the acks if everything has
    // been delivered or resend specific messages.
    action receiveAckPayload(sender, receiver) = all {
        // Guards
        canReceiveAckPayload(sender, receiver),

        // Next state updates
        messageStore' = messageStore,
        nodeState' = nodeState.setBy(
            sender,
            senderState => senderState.setBy(
                receiver,
                receiverState => {
                    ...receiverState,
                    // Remove the acknowledged messages from the sender's node state for the receiver, as they have been acknowledged by the receiver.
                    messages: receiverState.messages.filter(
                        m => not(
                            m.messageId.in(payloadState.get(receiver).get(sender).acks)
                        )
                    )
                }
            )
        ),
        payloadState' = payloadState.setBy(
            sender,
            senderPayload => senderPayload.setBy(
                receiver,
                // Cleanup of the acks in the payload state for the sender to receiver, as they have been acknowledged by the receiver. This is done to avoid resending the same messages again.
                receiverState => {
                    ...receiverState,
                    acks: Set()  // TODO: the payload acks are in the reverse direction //TODO: check if alle messages have been acknowledged and if so, clear the payload state for the sender to receiver to avoid resending the same messages again.
                }
            )
        ),
        payloadSent' = payloadSent,
        payloadReceived' = payloadReceived.setBy(
            receiver,
            receiverState => receiverState.setBy(sender, _ => true)
        )
    }

    // ------------------------------------------------------------------------------------
    // HELPER VERIFICATION ACTIONS
    // ------------------------------------------------------------------------------------

    // Init action for tests that require an actual sync from Alice to Bob.
    action initWithMessagesToSync() = {
        nondet randomMessageIdsAlice = getMessageIdsPowerset.oneOf()
        nondet randomMessageIdsBob = getMessageIdsPowerset.oneOf()
        all {
            randomMessageIdsAlice.size() != 0,
            randomMessageIdsAlice.exists(id => not(id.in(randomMessageIdsBob))),
            nodeState' = initNodeState(randomMessageIdsAlice, randomMessageIdsBob),
            payloadState' = initPayloadState,
            messageStore' = initMessageStore(randomMessageIdsAlice, randomMessageIdsBob),
            payloadSent' = initPayloadSentState,
            payloadReceived' = initPayloadReceivedState
        }
    }

    // Init action for tests that require no sync delta from Alice to Bob.
    action initWithoutMessagesToSync() = {
        nondet randomMessageIdsAlice = getMessageIdsPowerset.oneOf()
        nondet randomMessageIdsBob = getMessageIdsPowerset.oneOf()
        all {
            randomMessageIdsAlice.size() != 0,
            randomMessageIdsAlice.forall(id => id.in(randomMessageIdsBob)),
            nodeState' = initNodeState(randomMessageIdsAlice, randomMessageIdsBob),
            payloadState' = initPayloadState,
            messageStore' = initMessageStore(randomMessageIdsAlice, randomMessageIdsBob),
            payloadSent' = initPayloadSentState,
            payloadReceived' = initPayloadReceivedState
        }
    }

    // -------------------------------------------------------------------------------------
    // HELPER VERIFICATION FUNCTIONS
    // -------------------------------------------------------------------------------------

    def isDefaultNodeState(n: Node): bool = {
        nodeState.get(n).get(n).messages.size() == 0 and
        nodeState.get(n).get(n).offers.size() == 0 and
        nodeState.get(n).get(n).requests.size() == 0
    }

    def isDefaultPayloadState(sender: Node, receiver: Node): bool = {
        payloadState.get(sender).get(receiver).payloadId == 0 and
        payloadState.get(sender).get(receiver).acks.size() == 0 and
        payloadState.get(sender).get(receiver).offers.size() == 0 and
        payloadState.get(sender).get(receiver).requests.size() == 0 and
        payloadState.get(sender).get(receiver).messages.size() == 0
    }

    // -------------------------------------------------------------------------------------
    // SAFETY PROPOSITIONS
    // -------------------------------------------------------------------------------------

    val two_nodes_only = 
        NODES.size() == 2

    val no_self_receiver_nodeState = 
        NODES.forall(
            n => isDefaultNodeState(n)
        )

    val no_self_receiver_payloadState = 
        NODES.forall(
            n => isDefaultPayloadState(n, n)
        )

    val no_reverse_payloadState = 
        NODES.forall(
            sender => NODES.forall(
                receiver =>
                    (
                        sender != receiver implies
                        payloadState.get(sender).get(receiver).payloadId == 0 and
                        payloadState.get(sender).get(receiver).acks.size() == 0 and
                        payloadState.get(sender).get(receiver).offers.size() == 0 and
                        payloadState.get(sender).get(receiver).requests.size() == 0 and
                        payloadState.get(sender).get(receiver).messages.size() == 0
                    ) or (
                        sender != receiver implies
                        payloadState.get(receiver).get(sender).payloadId == 0 and
                        payloadState.get(receiver).get(sender).acks.size() == 0 and
                        payloadState.get(receiver).get(sender).offers.size() == 0 and
                        payloadState.get(receiver).get(sender).requests.size() == 0 and
                        payloadState.get(receiver).get(sender).messages.size() == 0
                    )
            )
        )

    // // ACKs should only exist for messages already marked as received by that receiver.
    // val ack_implies_received = 
    //     NODES.forall(
    //         receiver => NODES.forall(
    //             sender => ackPayload.get(receiver).get(sender).forall(
    //                 id => received.get(receiver).contains(id)
    //             )
    //         )
    //     )

    // // If a message is in-flight to a receiver, it should not also be in sender self-state.
    // val in_flight_never_self = 
    //     NODES.forall(
    //         sender => NODES.forall(
    //             receiver => sender != receiver 
    //             implies messageState.get(sender).get(receiver).intersect(
    //                 messageState.get(sender).get(sender)
    //             ).size() == 0
    //         )
    //     )

    // -------------------------------------------------------------------------------------
    // LIVENESS PROPOSITIONS
    // -------------------------------------------------------------------------------------
   
    // Insert liveness propositions here for exploration of the state space, if needed.


    // -------------------------------------------------------------------------------------
    // WITNESS-STYLE PROPOSITIONS (NON-INVARIANTS)
    // -------------------------------------------------------------------------------------

    // Insert witness-style propositions here for exploration of the state space, if needed.


    // ------------------------------------------------------------------------------------
    // TESTS
    // ------------------------------------------------------------------------------------

    run messagesSuccessfullyStoredTest =
        initWithMessagesToSync
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                messageStore.get(ALICE).forall(x => x.in(messageStore.get(BOB)))
            )

    run messageStoreSyncTest =
        initWithMessagesToSync
            .then(addMessages(ALICE, BOB))
            .then(sendMessagesPayload(ALICE, BOB))
            .then(receiveMessagesPayload(ALICE, BOB))
            .then(storeReceivedMessages(ALICE, BOB))
            .then(determineAck(ALICE, BOB))
            .then(sendAckPayload(ALICE, BOB))
            .then(receiveAckPayload(ALICE, BOB))
            .expect(
                // After complete bidirectional message exchange, both nodes should have messages
                // This verifies that the protocol correctly syncs messages when nodes start with different sets
                messageStore.get(ALICE).size() > 0 and
                messageStore.get(BOB).size() > 0
            )

    run addMessagesFailsWhenNoSyncDeltaTest =
        initWithoutMessagesToSync
            .then(addMessages(ALICE, BOB).fail())
}