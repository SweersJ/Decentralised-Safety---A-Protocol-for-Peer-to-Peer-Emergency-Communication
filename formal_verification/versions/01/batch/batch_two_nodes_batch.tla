--------------------------------- MODULE batch_two_nodes_batch ---------------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

VARIABLE
  (*
    @type: (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
  *)
  messageStore

VARIABLE
  (*
    @type: (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
  *)
  nodeState

VARIABLE
  (*
    @type: (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
  *)
  payloadState

VARIABLE
  (*
    @type: (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
  *)
  payloadExchangeState

CONSTANT
  (*
    @type: Set(Str);
  *)
  NODES

CONSTANT
  (*
    @type: (Str -> Set(Str));
  *)
  RANDOM_MESSAGE_IDS

(*
  @type: (((Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })), Str) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
getMessagesMessageStore(currentMessageStore_1035, node_1035) ==
  currentMessageStore_1035[node_1035]

(*
  @type: (((Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })), Str, Str) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
*)
getNodeState(currentNodeState_1053, sender_1053, receiver_1053) ==
  currentNodeState_1053[sender_1053][receiver_1053]

(*
  @type: ((Str, Str) => Bool);
*)
isPeerPair(sender_3130, receiver_3130) == sender_3130 /= receiver_3130

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
*)
getPayloadExchangeState(currentPayloadExchangeState_1217, sender_1217, receiver_1217) ==
  currentPayloadExchangeState_1217[sender_1217][receiver_1217]

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
MessagesSent == Variant("MessagesSent", [tag |-> "UNIT"])

(*
  @type: (((Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), Str, Str) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
*)
getPayload(currentPayloadState_1075, sender_1075, receiver_1075) ==
  currentPayloadState_1075[sender_1075][receiver_1075]

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
AckSent == Variant("AckSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
Idle == Variant("Idle", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
MessagesAdded == Variant("MessagesAdded", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
MessagesReceived == Variant("MessagesReceived", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
AckReceived == Variant("AckReceived", [tag |-> "UNIT"])

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str })) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
setPayloadExchangeStatePhase(currentPayloadExchangeState_3173, sender_3173, receiver_3173,
newPayloadExchangePhase_3173) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var1 == currentPayloadExchangeState_3173
  IN
  [
    (__quint_var1) EXCEPT
      ![sender_3173] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA5(senderState_3171) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var0 == senderState_3171
          IN
          [
            (__quint_var0) EXCEPT
              ![receiver_3173] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA4(receiverState_3169) ==
                  [
                    receiverState_3169 EXCEPT
                      !["phase"] = newPayloadExchangePhase_3173
                  ]
                IN
                __QUINT_LAMBDA4((__quint_var0)[receiver_3173])
          ]
        IN
        __QUINT_LAMBDA5((__quint_var1)[sender_3173])
  ]

(*
  @type: ((Set(Str), (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }))) => Bool);
*)
self_nodeState_is_always_empty_predicate(nodes_3433, currentNodeState_3433) ==
  \A n_3431 \in nodes_3433:
    LET (*
      @type: (() => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
    *)
    selfState == currentNodeState_3433[n_3431][n_3431]
    IN
    Cardinality((selfState)["messages"]) = 0
      /\ Cardinality((selfState)["offers"]) = 0
      /\ Cardinality((selfState)["requests"]) = 0

(*
  @type: (() => None({ tag: Str }) | Some(a));
*)
None == Variant("None", [tag |-> "UNIT"])

(*
  @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set(Str));
*)
getSetMessageIds(messages_992) ==
  { message_990["messageId"]: message_990 \in messages_992 }

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_message1 ==
  [messageId |->
      "741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75",
    groupId |-> "group-alpha",
    timestamp |-> 1751966400,
    body |-> "Need insulin at shelter A"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_message2 ==
  [messageId |->
      "12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c",
    groupId |-> "group-alpha",
    timestamp |-> 1751966400,
    body |-> "Offer: 2L water near station"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_message3 ==
  [messageId |->
      "4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1",
    groupId |-> "group-bravo",
    timestamp |-> 1751966400,
    body |-> "Request: flashlight batteries"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_message4 ==
  [messageId |->
      "f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e",
    groupId |-> "group-charlie",
    timestamp |-> 1751966400,
    body |-> "Road blocked at bridge"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_message5 ==
  [messageId |->
      "2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541",
    groupId |-> "group-charlie",
    timestamp |-> 1751966400,
    body |-> "Medic available at checkpoint"]

(*
  @type: (() => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
*)
batch_init_helpers_EMPTY_NODE_STATE ==
  [offers |-> {}, requests |-> {}, messages |-> {}]

(*
  @type: (((b -> c), b) => Bool);
*)
batch_init_helpers_has(batch_init_helpers_m_346, batch_init_helpers_key_346) ==
  batch_init_helpers_key_346 \in DOMAIN batch_init_helpers_m_346

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_EMPTY_MESSAGE ==
  [messageId |-> "", groupId |-> "", timestamp |-> 0, body |-> ""]

(*
  @type: (() => None({ tag: Str }) | Some(g));
*)
batch_init_helpers_None == Variant("None", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_init_helpers_Idle == Variant("Idle", [tag |-> "UNIT"])

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }), Bool, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
setPayloadExchangeState(currentPayloadExchangeState_3279, sender_3279, receiver_3279,
newPayloadExchangePhase_3279, newMessagesStored_3279, newAckDetermined_3279) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var3 == currentPayloadExchangeState_3279
  IN
  [
    (__quint_var3) EXCEPT
      ![sender_3279] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA9(senderState_3277) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var2 == senderState_3277
          IN
          [
            (__quint_var2) EXCEPT
              ![receiver_3279] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA8(receiverState_3275) ==
                  [phase |-> newPayloadExchangePhase_3279,
                    messagesStored |-> newMessagesStored_3279,
                    ackDetermined |-> newAckDetermined_3279]
                IN
                __QUINT_LAMBDA8((__quint_var2)[receiver_3279])
          ]
        IN
        __QUINT_LAMBDA9((__quint_var3)[sender_3279])
  ]

(*
  @type: ((i) => None({ tag: Str }) | Some(i));
*)
Some(__SomeParam_248) == Variant("Some", __SomeParam_248)

(*
  @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
excludeMessagesById(messages_1012, ids_1012) ==
  { message_1010 \in messages_1012: ~(message_1010["messageId"] \in ids_1012) }

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
setPayloadExchangeStateMessagesStored(currentPayloadExchangeState_3239, sender_3239,
receiver_3239, newMessagesStored_3239) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var7 == currentPayloadExchangeState_3239
  IN
  [
    (__quint_var7) EXCEPT
      ![sender_3239] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA15(senderState_3237) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var6 == senderState_3237
          IN
          [
            (__quint_var6) EXCEPT
              ![receiver_3239] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA14(receiverState_3235) ==
                  [
                    receiverState_3235 EXCEPT
                      !["messagesStored"] = newMessagesStored_3239
                  ]
                IN
                __QUINT_LAMBDA14((__quint_var6)[receiver_3239])
          ]
        IN
        __QUINT_LAMBDA15((__quint_var7)[sender_3239])
  ]

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
setPayloadExchangeStateAckDetermined(currentPayloadExchangeState_3206, sender_3206,
receiver_3206, newAckDetermined_3206) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var12 == currentPayloadExchangeState_3206
  IN
  [
    (__quint_var12) EXCEPT
      ![sender_3206] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA20(senderState_3204) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var11 == senderState_3204
          IN
          [
            (__quint_var11) EXCEPT
              ![receiver_3206] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA19(receiverState_3202) ==
                  [
                    receiverState_3202 EXCEPT
                      !["ackDetermined"] = newAckDetermined_3206
                  ]
                IN
                __QUINT_LAMBDA19((__quint_var11)[receiver_3206])
          ]
        IN
        __QUINT_LAMBDA20((__quint_var12)[sender_3206])
  ]

(*
  @type: ((Str, Str) => Bool);
*)
hasSyncDelta(sender_1330, receiver_1330) ==
  Cardinality((getMessagesMessageStore(messageStore, sender_1330))) > 0
    /\ Cardinality((getNodeState(nodeState, sender_1330, receiver_1330))[
      "messages"
    ])
      > 0

(*
  @type: ((Str, Str) => Bool);
*)
canReceiveMessagesPayload(sender_1409, receiver_1409) ==
  isPeerPair(sender_1409, receiver_1409)
    /\ (getPayloadExchangeState(payloadExchangeState, sender_1409, receiver_1409))[
      "phase"
    ]
      = MessagesSent

(*
  @type: (((Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), Str, Str) => Set(Str));
*)
getPayloadAcks(currentPayloadState_1137, sender_1137, receiver_1137) ==
  CASE VariantTag((getPayload(currentPayloadState_1137, sender_1137, receiver_1137)))
      = "Some"
      -> LET (*
        @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => Set(Str));
      *)
      __QUINT_LAMBDA0(payload_1132) == payload_1132["acks"]
      IN
      __QUINT_LAMBDA0(VariantGetUnsafe("Some", (getPayload(currentPayloadState_1137,
      sender_1137, receiver_1137))))
    [] VariantTag((getPayload(currentPayloadState_1137, sender_1137, receiver_1137)))
      = "None"
      -> LET (*
        @type: (({ tag: Str }) => Set(Str));
      *)
      __QUINT_LAMBDA1(id__1135) == {}
      IN
      __QUINT_LAMBDA1(VariantGetUnsafe("None", (getPayload(currentPayloadState_1137,
      sender_1137, receiver_1137))))

(*
  @type: (((Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), Str, Str) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
getPayloadMessages(currentPayloadState_1106, sender_1106, receiver_1106) ==
  CASE VariantTag((getPayload(currentPayloadState_1106, sender_1106, receiver_1106)))
      = "Some"
      -> LET (*
        @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
      *)
      __QUINT_LAMBDA2(payload_1101) == payload_1101["messages"]
      IN
      __QUINT_LAMBDA2(VariantGetUnsafe("Some", (getPayload(currentPayloadState_1106,
      sender_1106, receiver_1106))))
    [] VariantTag((getPayload(currentPayloadState_1106, sender_1106, receiver_1106)))
      = "None"
      -> LET (*
        @type: (({ tag: Str }) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
      *)
      __QUINT_LAMBDA3(id__1104) == {}
      IN
      __QUINT_LAMBDA3(VariantGetUnsafe("None", (getPayload(currentPayloadState_1106,
      sender_1106, receiver_1106))))

(*
  @type: ((Str, Str) => Bool);
*)
canStoreReceivedMessages(sender_1435, receiver_1435) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
  *)
  state ==
    getPayloadExchangeState(payloadExchangeState, sender_1435, receiver_1435)
  IN
  isPeerPair(sender_1435, receiver_1435)
    /\ (state)["phase"] = MessagesReceived
    /\ ~((state)["messagesStored"])

(*
  @type: ((Str, Str) => Bool);
*)
canDetermineAck(sender_1461, receiver_1461) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
  *)
  state ==
    getPayloadExchangeState(payloadExchangeState, sender_1461, receiver_1461)
  IN
  isPeerPair(sender_1461, receiver_1461)
    /\ (state)["phase"] = MessagesReceived
    /\ ~((state)["ackDetermined"])

(*
  @type: ((Str, Str) => Bool);
*)
canAckPayload(sender_1489, receiver_1489) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
  *)
  state ==
    getPayloadExchangeState(payloadExchangeState, sender_1489, receiver_1489)
  IN
  isPeerPair(sender_1489, receiver_1489)
    /\ (state)["phase"] = MessagesReceived
    /\ (state)["messagesStored"]
    /\ (state)["ackDetermined"]

(*
  @type: ((Str, Str) => Bool);
*)
canIdle(sender_1541, receiver_1541) ==
  LET (*
    @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
  *)
  phase ==
    (getPayloadExchangeState(payloadExchangeState, sender_1541, receiver_1541))[
      "phase"
    ]
  IN
  isPeerPair(sender_1541, receiver_1541)
    /\ (phase = Idle \/ phase = AckReceived)

(*
  @type: (() => Bool);
*)
self_nodeState_is_always_empty ==
  self_nodeState_is_always_empty_predicate(NODES, nodeState)

(*
  @type: ((Set(Str), (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })))) => Bool);
*)
self_payloadState_is_always_empty_predicate(nodes_3462, currentPayloadState_3462) ==
  \A n_3460 \in nodes_3462: currentPayloadState_3462[n_3460][n_3460] = None

(*
  @type: ((Set(Str), (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }))) => Bool);
*)
reverse_payloadState_is_always_empty_predicate(nodes_3588, currentPayloadState_3588,
currentPayloadExchangeState_3588) ==
  \A sender_3586 \in nodes_3588:
    \A receiver_3584 \in nodes_3588:
      sender_3586 /= receiver_3584
        => (LET (*
          @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
        *)
        forwardPhase ==
          (getPayloadExchangeState(currentPayloadExchangeState_3588, sender_3586,
          receiver_3584))[
            "phase"
          ]
        IN
        LET (*
          @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
        *)
        reversePhase ==
          (getPayloadExchangeState(currentPayloadExchangeState_3588, receiver_3584,
          sender_3586))[
            "phase"
          ]
        IN
        LET (*
          @type: (() => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
        *)
        forwardPayload ==
          getPayload(currentPayloadState_3588, sender_3586, receiver_3584)
        IN
        LET (*
          @type: (() => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
        *)
        reversePayload ==
          getPayload(currentPayloadState_3588, receiver_3584, sender_3586)
        IN
        LET (*
          @type: (() => Bool);
        *)
        forwardInactive == forwardPhase = Idle \/ forwardPhase = AckReceived
        IN
        LET (*
          @type: (() => Bool);
        *)
        reverseInactive == reversePhase = Idle \/ reversePhase = AckReceived
        IN
        (forwardInactive /\ reverseInactive)
          \/ (((~forwardInactive /\ reverseInactive) /\ forwardPayload /= None)
            /\ reversePayload = None)
          \/ (((forwardInactive /\ ~reverseInactive) /\ forwardPayload = None)
            /\ reversePayload /= None)
          \/ (((~forwardInactive /\ ~reverseInactive) /\ forwardPayload /= None)
            /\ reversePayload /= None))

(*
  @type: ((Set(Str), (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }))) => Bool);
*)
self_payloadExchangeState_is_always_empty_predicate(nodes_3630, currentPayloadExchangeState_3630) ==
  \A n_3628 \in nodes_3630:
    LET (*
      @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
    *)
    selfState == currentPayloadExchangeState_3630[n_3628][n_3628]
    IN
    (selfState)["phase"] = Idle
      /\ ~((selfState)["messagesStored"])
      /\ ~((selfState)["ackDetermined"])

(*
  @type: (() => Bool);
*)
pending_messages_belong_to_sender ==
  \A sender_2143 \in NODES:
    \A receiver_2141 \in NODES:
      isPeerPair(sender_2143, receiver_2141)
        => (\A m_2138 \in (getNodeState(nodeState, sender_2143, receiver_2141))[
          "messages"
        ]:
          m_2138 \in getMessagesMessageStore(messageStore, sender_2143))

(*
  @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => Set(Str));
*)
payloadMessageIds(payload_3361) ==
  CASE VariantTag(payload_3361) = "Some"
      -> LET (*
        @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => Set(Str));
      *)
      __QUINT_LAMBDA6(value_3356) == getSetMessageIds(value_3356["messages"])
      IN
      __QUINT_LAMBDA6(VariantGetUnsafe("Some", payload_3361))
    [] VariantTag(payload_3361) = "None"
      -> LET (*
        @type: (({ tag: Str }) => Set(Str));
      *)
      __QUINT_LAMBDA7(id__3359) == {}
      IN
      __QUINT_LAMBDA7(VariantGetUnsafe("None", payload_3361))

(*
  @type: (() => Bool);
*)
when_idle_not_messageStored_and_not_ackDetermined ==
  \A sender_2297 \in NODES:
    \A receiver_2295 \in NODES:
      isPeerPair(sender_2297, receiver_2295)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2297, receiver_2295))[
          "phase"
        ]
          = Idle
          => ~((getPayloadExchangeState(payloadExchangeState, sender_2297, receiver_2295))[
              "messagesStored"
            ])
            /\ ~((getPayloadExchangeState(payloadExchangeState, sender_2297, receiver_2295))[
              "ackDetermined"
            ]))

(*
  @type: (() => Bool);
*)
when_ackDetermined ==
  \A sender_2457 \in NODES:
    \A receiver_2455 \in NODES:
      isPeerPair(sender_2457, receiver_2455)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2457, receiver_2455))[
          "ackDetermined"
        ]
          => (getPayloadExchangeState(payloadExchangeState, sender_2457, receiver_2455))[
            "phase"
          ]
            \in { (MessagesReceived), (AckSent), (AckReceived) })

(*
  @type: (() => Bool);
*)
when_messagesStored ==
  \A sender_2488 \in NODES:
    \A receiver_2486 \in NODES:
      isPeerPair(sender_2488, receiver_2486)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2488, receiver_2486))[
          "messagesStored"
        ]
          => (getPayloadExchangeState(payloadExchangeState, sender_2488, receiver_2486))[
            "phase"
          ]
            \in { (MessagesReceived), (AckSent), (AckReceived) })

(*
  @type: (() => Bool);
*)
messageStores_are_monotonic == 
  [][
    \A n_2609 \in NODES: 
      messageStore[n_2609] \subseteq messageStore[n_2609]'
  ]_messageStore

\* Original version
\* messageStores_are_monotonic ==
\*   [](\A n_2609 \in NODES: messageStore[n_2609] \subseteq messageStore[n_2609]')

(*
  @type: (() => (Str -> { body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_init_helpers_MESSAGES ==
  SetAsFun({ <<
      (batch_init_helpers_message1)["messageId"], (batch_init_helpers_message1)
    >>,
    <<
      (batch_init_helpers_message2)["messageId"], (batch_init_helpers_message2)
    >>,
    <<
      (batch_init_helpers_message3)["messageId"], (batch_init_helpers_message3)
    >>,
    <<
      (batch_init_helpers_message4)["messageId"], (batch_init_helpers_message4)
    >>,
    <<
      (batch_init_helpers_message5)["messageId"], (batch_init_helpers_message5)
    >> })

(*
  @type: (() => Bool);
*)
can_have_pending_messages ==
  \E sender_2906 \in NODES:
    \E receiver_2904 \in NODES:
      isPeerPair(sender_2906, receiver_2904)
        /\ Cardinality((getNodeState(nodeState, sender_2906, receiver_2904))[
          "messages"
        ])
          > 0

(*
  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => Bool);
*)
hasInFlightMessagesPayload(state_3371) == state_3371["phase"] = MessagesSent

(*
  @type: (() => Bool);
*)
can_have_delivered_payload ==
  \E sender_2985 \in NODES:
    \E receiver_2983 \in NODES:
      isPeerPair(sender_2985, receiver_2983)
        /\ (getPayloadExchangeState(payloadExchangeState, sender_2985, receiver_2983))[
          "phase"
        ]
          = MessagesReceived

(*
  @type: (() => Set(Str));
*)
batch_init_helpers_INIT_NODES == NODES

(*
  @type: (((d -> e), d, e) => e);
*)
batch_init_helpers_getOrElse(batch_init_helpers_m_365, batch_init_helpers_key_365,
batch_init_helpers_default_365) ==
  IF batch_init_helpers_has(batch_init_helpers_m_365, batch_init_helpers_key_365)
  THEN batch_init_helpers_m_365[batch_init_helpers_key_365]
  ELSE batch_init_helpers_default_365

(*
  @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
*)
batch_init_helpers_EMPTY_PAYLOAD_EXCHANGE_STATE ==
  [phase |-> batch_init_helpers_Idle,
    messagesStored |-> FALSE,
    ackDetermined |-> FALSE]

(*
  @type: ((Str, Str) => Bool);
*)
canReceiveAckPayload(sender_1515, receiver_1515) ==
  isPeerPair(sender_1515, receiver_1515)
    /\ Cardinality((getPayloadAcks(payloadState, sender_1515, receiver_1515)))
      /= 0
    /\ (getPayloadExchangeState(payloadExchangeState, sender_1515, receiver_1515))[
      "phase"
    ]
      = AckSent

(*
  @type: ((Str, Str) => Bool);
*)
canAddMessages(sender_1352, receiver_1352) ==
  isPeerPair(sender_1352, receiver_1352)
    /\ hasSyncDelta(sender_1352, receiver_1352)
    /\ (getPayloadExchangeState(payloadExchangeState, sender_1352, receiver_1352))[
      "phase"
    ]
      = Idle

(*
  @type: ((Str, Str) => Bool);
*)
canSendMessagesPayload(sender_1390, receiver_1390) ==
  isPeerPair(sender_1390, receiver_1390)
    /\ hasSyncDelta(sender_1390, receiver_1390)
    /\ Cardinality((getPayloadMessages(payloadState, sender_1390, receiver_1390)))
      /= 0
    /\ Cardinality((getNodeState(nodeState, sender_1390, receiver_1390))[
      "messages"
    ])
      /= 0
    /\ (getPayloadExchangeState(payloadExchangeState, sender_1390, receiver_1390))[
      "phase"
    ]
      = MessagesAdded

(*
  @type: ((Str, Str) => Bool);
*)
receiveMessagesPayload(sender_1761, receiver_1761) ==
  canReceiveMessagesPayload(sender_1761, receiver_1761)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (setPayloadExchangeStatePhase(payloadExchangeState, sender_1761, receiver_1761,
      (MessagesReceived)))

(*
  @type: (() => Bool);
*)
self_payloadState_is_always_empty ==
  self_payloadState_is_always_empty_predicate(NODES, payloadState)

(*
  @type: (() => Bool);
*)
reverse_payloadState_is_always_empty ==
  reverse_payloadState_is_always_empty_predicate(NODES, payloadState, payloadExchangeState)

(*
  @type: (() => Bool);
*)
self_payloadExchangeState_is_always_empty ==
  self_payloadExchangeState_is_always_empty_predicate(NODES, payloadExchangeState)

(*
  @type: (() => Bool);
*)
payload_messages_are_pending_or_known_by_receiver ==
  \A sender_2086 \in NODES:
    \A receiver_2084 \in NODES:
      isPeerPair(sender_2086, receiver_2084)
        => (\A m_2081 \in getPayloadMessages(payloadState, sender_2086, receiver_2084):
          m_2081
              \in (getNodeState(nodeState, sender_2086, receiver_2084))[
                "messages"
              ]
            \/ m_2081 \in getMessagesMessageStore(messageStore, receiver_2084))

(*
  @type: (() => Bool);
*)
payload_messages_belong_to_sender ==
  \A sender_2111 \in NODES:
    \A receiver_2109 \in NODES:
      isPeerPair(sender_2111, receiver_2109)
        => (\A m_2106 \in getPayloadMessages(payloadState, sender_2111, receiver_2109):
          m_2106 \in getMessagesMessageStore(messageStore, sender_2111))

(*
  @type: (() => Bool);
*)
ack_ids_match_payload_messages ==
  \A sender_2166 \in NODES:
    \A receiver_2164 \in NODES:
      \A id_2162 \in getPayloadAcks(payloadState, sender_2166, receiver_2164):
        id_2162
          \in payloadMessageIds((getPayload(payloadState, sender_2166, receiver_2164)))

(*
  @type: (() => Bool);
*)
sent_ack_ids_match_stored_messages ==
  \A sender_2201 \in NODES:
    \A receiver_2199 \in NODES:
      isPeerPair(sender_2201, receiver_2199)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2201, receiver_2199))[
          "phase"
        ]
          = AckSent
          => (\A id_2195 \in getPayloadAcks(payloadState, sender_2201, receiver_2199):
            id_2195 \in getSetMessageIds(messageStore[receiver_2199])))

(*
  @type: (() => Bool);
*)
pending_acks_imply_nonempty_payload ==
  \A sender_2230 \in NODES:
    \A receiver_2228 \in NODES:
      Cardinality((getPayloadAcks(payloadState, sender_2230, receiver_2228)))
        > 0
        => Cardinality((getPayloadMessages(payloadState, sender_2230, receiver_2228)))
          > 0

(*
  @type: (() => Bool);
*)
determined_ack_covers_payload ==
  \A sender_2260 \in NODES:
    \A receiver_2258 \in NODES:
      isPeerPair(sender_2260, receiver_2258)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2260, receiver_2258))[
          "ackDetermined"
        ]
          => getPayloadAcks(payloadState, sender_2260, receiver_2258)
            = payloadMessageIds((getPayload(payloadState, sender_2260, receiver_2258))))

(*
  @type: (() => Bool);
*)
when_MessagesAdded_payload_messages_non_empty ==
  \A sender_2326 \in NODES:
    \A receiver_2324 \in NODES:
      isPeerPair(sender_2326, receiver_2324)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2326, receiver_2324))[
          "phase"
        ]
          = MessagesAdded
          => Cardinality((getPayloadMessages(payloadState, sender_2326, receiver_2324)))
            > 0)

(*
  @type: (() => Bool);
*)
when_MessagesSent_payload_messages_non_empty ==
  \A sender_2355 \in NODES:
    \A receiver_2353 \in NODES:
      isPeerPair(sender_2355, receiver_2353)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2355, receiver_2353))[
          "phase"
        ]
          = MessagesSent
          => Cardinality((getPayloadMessages(payloadState, sender_2355, receiver_2353)))
            > 0)

(*
  @type: (() => Bool);
*)
when_AckSent_messagesStored_ackDetermined_acks_non_empty ==
  \A sender_2397 \in NODES:
    \A receiver_2395 \in NODES:
      isPeerPair(sender_2397, receiver_2395)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2397, receiver_2395))[
          "phase"
        ]
          = AckSent
          => (getPayloadExchangeState(payloadExchangeState, sender_2397, receiver_2395))[
              "messagesStored"
            ]
            /\ (getPayloadExchangeState(payloadExchangeState, sender_2397, receiver_2395))[
              "ackDetermined"
            ]
            /\ Cardinality((getPayloadAcks(payloadState, sender_2397, receiver_2395)))
              > 0)

(*
  @type: (() => Bool);
*)
when_AckReceived_acks_empty ==
  \A sender_2426 \in NODES:
    \A receiver_2424 \in NODES:
      isPeerPair(sender_2426, receiver_2424)
        => ((getPayloadExchangeState(payloadExchangeState, sender_2426, receiver_2424))[
          "phase"
        ]
          = AckReceived
          => Cardinality((getPayloadAcks(payloadState, sender_2426, receiver_2424)))
            = 0)

(*
  @type: (() => Bool);
*)
pending_message_id_removed_only_after_storage ==
  [][
    \A sender_2760 \in NODES:
      \A receiver_2758 \in NODES:
        \A id_2755 \in DOMAIN batch_init_helpers_MESSAGES:
          isPeerPair(sender_2760, receiver_2758)
            => (
              (
                /\ id_2755 \in getSetMessageIds(
                  (
                    getNodeState(nodeState, sender_2760, receiver_2758)
                  )["messages"]
                )
                /\ id_2755 \notin getSetMessageIds(
                  (
                    getNodeState(nodeState', sender_2760, receiver_2758)
                  )["messages"]
                )
              )
              => id_2755 \in getSetMessageIds(
                (
                  getMessagesMessageStore(messageStore', receiver_2758)
                )
              )
            )
  ]_<<nodeState, messageStore>>

\* Original version
\* pending_message_id_removed_only_after_storage ==
\*   \A sender_2760 \in NODES:
\*     \A receiver_2758 \in NODES:
\*       isPeerPair(sender_2760, receiver_2758)
\*         => (\A id_2755 \in DOMAIN batch_init_helpers_MESSAGES:
\*           [](id_2755
\*               \in getSetMessageIds((getNodeState(nodeState, sender_2760, receiver_2758))[
\*                 "messages"
\*               ])
\*             /\ ~(id_2755
\*               \in getSetMessageIds((getNodeState(nodeState, sender_2760, receiver_2758))[
\*                 "messages"
\*               ]))'
\*             => (id_2755
\*               \in getSetMessageIds((getMessagesMessageStore(messageStore, receiver_2758))))'))

(*
  @type: (() => Bool);
*)
can_have_payload_messages ==
  \E sender_2926 \in NODES:
    \E receiver_2924 \in NODES:
      isPeerPair(sender_2926, receiver_2924)
        /\ Cardinality((getPayloadMessages(payloadState, sender_2926, receiver_2924)))
          > 0

(*
  @type: (() => Bool);
*)
can_have_in_flight_payload ==
  \E sender_2944 \in NODES:
    \E receiver_2942 \in NODES:
      isPeerPair(sender_2944, receiver_2942)
        /\ hasInFlightMessagesPayload((getPayloadExchangeState(payloadExchangeState,
        sender_2944, receiver_2942)))

(*
  @type: (() => Bool);
*)
can_have_pending_acks ==
  \E sender_2964 \in NODES:
    \E receiver_2962 \in NODES:
      isPeerPair(sender_2964, receiver_2962)
        /\ Cardinality((getPayloadAcks(payloadState, sender_2964, receiver_2962)))
          > 0

(*
  @type: ((Str) => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_init_helpers_getMessage(batch_init_helpers_messageId_953) ==
  batch_init_helpers_getOrElse((batch_init_helpers_MESSAGES), batch_init_helpers_messageId_953,
  (batch_init_helpers_EMPTY_MESSAGE))

(*
  @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
*)
batch_init_helpers_initPayloadState ==
  [
    batch_init_helpers___3073 \in batch_init_helpers_INIT_NODES |->
      [
        batch_init_helpers___3071 \in batch_init_helpers_INIT_NODES |->
          batch_init_helpers_None
      ]
  ]

(*
  @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
batch_init_helpers_initPayloadExchangeState ==
  [
    batch_init_helpers_sender_3107 \in batch_init_helpers_INIT_NODES |->
      [
        batch_init_helpers_receiver_3105 \in batch_init_helpers_INIT_NODES |->
          batch_init_helpers_EMPTY_PAYLOAD_EXCHANGE_STATE
      ]
  ]

(*
  @type: ((Str, Str) => Bool);
*)
idle(sender_1641, receiver_1641) ==
  canIdle(sender_1641, receiver_1641)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (setPayloadExchangeState(payloadExchangeState, sender_1641, receiver_1641,
      (Idle), FALSE, FALSE))

(*
  @type: ((Str, Str) => Bool);
*)
storeReceivedMessages(sender_1816, receiver_1816) ==
  canStoreReceivedMessages(sender_1816, receiver_1816)
    /\ messageStore'
      := (LET (*
        @type: (() => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
      *)
      __quint_var8 == messageStore
      IN
      [
        (__quint_var8) EXCEPT
          ![receiver_1816] =
            LET (*
              @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
            *)
            __QUINT_LAMBDA16(receiverStore_1777) ==
              receiverStore_1777
                \union getPayloadMessages(payloadState, sender_1816, receiver_1816)
            IN
            __QUINT_LAMBDA16((__quint_var8)[receiver_1816])
      ])
    /\ nodeState'
      := (LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })));
      *)
      __quint_var10 == nodeState
      IN
      [
        (__quint_var10) EXCEPT
          ![receiver_1816] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA18(receiverState_1801) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
              *)
              __quint_var9 == receiverState_1801
              IN
              [
                (__quint_var9) EXCEPT
                  ![sender_1816] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA17(senderState_1799) ==
                      [
                        senderState_1799 EXCEPT
                          !["messages"] =
                            excludeMessagesById(senderState_1799["messages"], (getSetMessageIds((getPayloadMessages(payloadState,
                            sender_1816, receiver_1816)))))
                      ]
                    IN
                    __QUINT_LAMBDA17((__quint_var9)[sender_1816])
              ]
            IN
            __QUINT_LAMBDA18((__quint_var10)[receiver_1816])
      ])
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (setPayloadExchangeStateMessagesStored(payloadExchangeState, sender_1816,
      receiver_1816, TRUE))

(*
  @type: ((Str, Str) => Bool);
*)
determineAck(sender_1866, receiver_1866) ==
  canDetermineAck(sender_1866, receiver_1866)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
      *)
      __quint_var14 == payloadState
      IN
      [
        (__quint_var14) EXCEPT
          ![sender_1866] =
            LET (*
              @type: (((Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))) => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
            *)
            __QUINT_LAMBDA24(senderPayload_1854) ==
              LET (*
                @type: (() => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
              *)
              __quint_var13 == senderPayload_1854
              IN
              [
                (__quint_var13) EXCEPT
                  ![receiver_1866] =
                    LET (*
                      @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                    *)
                    __QUINT_LAMBDA23(receiverPayload_1852) ==
                      CASE VariantTag(receiverPayload_1852) = "Some"
                          -> LET (*
                            @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA21(payload_1847) ==
                            Some([
                              payload_1847 EXCEPT
                                !["acks"] =
                                  getSetMessageIds(payload_1847["messages"])
                            ])
                          IN
                          __QUINT_LAMBDA21(VariantGetUnsafe("Some", receiverPayload_1852))
                        [] VariantTag(receiverPayload_1852) = "None"
                          -> LET (*
                            @type: (({ tag: Str }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA22(id__1850) == None
                          IN
                          __QUINT_LAMBDA22(VariantGetUnsafe("None", receiverPayload_1852))
                    IN
                    __QUINT_LAMBDA23((__quint_var13)[receiver_1866])
              ]
            IN
            __QUINT_LAMBDA24((__quint_var14)[sender_1866])
      ])
    /\ payloadExchangeState'
      := (setPayloadExchangeStateAckDetermined(payloadExchangeState, sender_1866,
      receiver_1866, TRUE))

(*
  @type: ((Str, Str) => Bool);
*)
sendAckPayload(sender_1890, receiver_1890) ==
  canAckPayload(sender_1890, receiver_1890)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (setPayloadExchangeStatePhase(payloadExchangeState, sender_1890, receiver_1890,
      (AckSent)))

(*
  @type: ((Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_init_helpers_getMessages(batch_init_helpers_messageIds_966) ==
  {
    batch_init_helpers_getMessage(batch_init_helpers_id_964):
      batch_init_helpers_id_964 \in batch_init_helpers_messageIds_966
  }

(*
  @type: ((Str, Str) => Bool);
*)
addMessages(sender_1713, receiver_1713) ==
  canAddMessages(sender_1713, receiver_1713)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
      *)
      __quint_var5 == payloadState
      IN
      [
        (__quint_var5) EXCEPT
          ![sender_1713] =
            LET (*
              @type: (((Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))) => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
            *)
            __QUINT_LAMBDA13(senderPayload_1701) ==
              LET (*
                @type: (() => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
              *)
              __quint_var4 == senderPayload_1701
              IN
              [
                (__quint_var4) EXCEPT
                  ![receiver_1713] =
                    LET (*
                      @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                    *)
                    __QUINT_LAMBDA12(receiverPayload_1699) ==
                      CASE VariantTag(receiverPayload_1699) = "None"
                          -> LET (*
                            @type: (({ tag: Str }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA10(id__1694) ==
                            Some([payloadId |-> 0,
                              offers |-> {},
                              requests |-> {},
                              acks |-> {},
                              messages |->
                                (getNodeState(nodeState, sender_1713, receiver_1713))[
                                  "messages"
                                ]])
                          IN
                          __QUINT_LAMBDA10(VariantGetUnsafe("None", receiverPayload_1699))
                        [] VariantTag(receiverPayload_1699) = "Some"
                          -> LET (*
                            @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA11(payload_1697) ==
                            Some([
                              payload_1697 EXCEPT
                                !["messages"] =
                                  payload_1697["messages"]
                                    \union (getNodeState(nodeState, sender_1713,
                                    receiver_1713))[
                                      "messages"
                                    ]
                            ])
                          IN
                          __QUINT_LAMBDA11(VariantGetUnsafe("Some", receiverPayload_1699))
                    IN
                    __QUINT_LAMBDA12((__quint_var4)[receiver_1713])
              ]
            IN
            __QUINT_LAMBDA13((__quint_var5)[sender_1713])
      ])
    /\ payloadExchangeState'
      := (setPayloadExchangeStatePhase(payloadExchangeState, sender_1713, receiver_1713,
      (MessagesAdded)))

(*
  @type: ((Str, Str) => Bool);
*)
sendMessagesPayload(sender_1737, receiver_1737) ==
  canSendMessagesPayload(sender_1737, receiver_1737)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (setPayloadExchangeStatePhase(payloadExchangeState, sender_1737, receiver_1737,
      (MessagesSent)))

(*
  @type: ((Str, Str) => Bool);
*)
receiveAckPayload(sender_1982, receiver_1982) ==
  canReceiveAckPayload(sender_1982, receiver_1982)
    /\ messageStore' := messageStore
    /\ nodeState'
      := (LET (*
        @type: (() => Set(Str));
      *)
      ackIds == getPayloadAcks(payloadState, sender_1982, receiver_1982)
      IN
      LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })));
      *)
      __quint_var16 == nodeState
      IN
      [
        (__quint_var16) EXCEPT
          ![sender_1982] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA26(senderState_1921) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
              *)
              __quint_var15 == senderState_1921
              IN
              [
                (__quint_var15) EXCEPT
                  ![receiver_1982] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA25(receiverState_1919) ==
                      [
                        receiverState_1919 EXCEPT
                          !["messages"] =
                            excludeMessagesById(receiverState_1919["messages"], (ackIds))
                      ]
                    IN
                    __QUINT_LAMBDA25((__quint_var15)[receiver_1982])
              ]
            IN
            __QUINT_LAMBDA26((__quint_var16)[sender_1982])
      ])
    /\ payloadState'
      := (LET (*
        @type: (() => Set(Str));
      *)
      ackIds == getPayloadAcks(payloadState, sender_1982, receiver_1982)
      IN
      LET (*
        @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
      *)
      __quint_var18 == payloadState
      IN
      [
        (__quint_var18) EXCEPT
          ![sender_1982] =
            LET (*
              @type: (((Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))) => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
            *)
            __QUINT_LAMBDA30(senderPayload_1969) ==
              LET (*
                @type: (() => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
              *)
              __quint_var17 == senderPayload_1969
              IN
              [
                (__quint_var17) EXCEPT
                  ![receiver_1982] =
                    LET (*
                      @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                    *)
                    __QUINT_LAMBDA29(receiverPayload_1967) ==
                      CASE VariantTag(receiverPayload_1967) = "Some"
                          -> LET (*
                            @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA27(payload_1962) ==
                            LET (*
                              @type: (() => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
                            *)
                            remainingMessages ==
                              excludeMessagesById(payload_1962["messages"], (ackIds))
                            IN
                            IF Cardinality((remainingMessages)) = 0
                            THEN None
                            ELSE Some([
                              [ payload_1962 EXCEPT !["acks"] = {} ] EXCEPT
                                !["messages"] = remainingMessages
                            ])
                          IN
                          __QUINT_LAMBDA27(VariantGetUnsafe("Some", receiverPayload_1967))
                        [] VariantTag(receiverPayload_1967) = "None"
                          -> LET (*
                            @type: (({ tag: Str }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA28(id__1965) == None
                          IN
                          __QUINT_LAMBDA28(VariantGetUnsafe("None", receiverPayload_1967))
                    IN
                    __QUINT_LAMBDA29((__quint_var17)[receiver_1982])
              ]
            IN
            __QUINT_LAMBDA30((__quint_var18)[sender_1982])
      ])
    /\ payloadExchangeState'
      := (setPayloadExchangeStatePhase(payloadExchangeState, sender_1982, receiver_1982,
      (AckReceived)))

(*
  @type: (() => Bool);
*)
payload_message_invariant ==
  payload_messages_are_pending_or_known_by_receiver
    /\ payload_messages_belong_to_sender
    /\ pending_messages_belong_to_sender

(*
  @type: (() => Bool);
*)
sent_acks_are_sound ==
  sent_ack_ids_match_stored_messages
    /\ ack_ids_match_payload_messages
    /\ pending_acks_imply_nonempty_payload

(*
  @type: (() => Bool);
*)
someReceiveMessagesPayload ==
  \E sender \in NODES:
    \E receiver \in { n_1992 \in NODES: n_1992 /= sender }:
      receiveMessagesPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
someDetermineAck ==
  \E sender \in NODES:
    \E receiver \in { n_2010 \in NODES: n_2010 /= sender }:
      determineAck(sender, receiver)

(*
  @type: (((Str -> Set(Str))) => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })));
*)
batch_init_helpers_initNodeState(batch_init_helpers_randomMessageIds_3057) ==
  [
    batch_init_helpers_sender_3055 \in batch_init_helpers_INIT_NODES |->
      [
        batch_init_helpers_receiver_3053 \in batch_init_helpers_INIT_NODES |->
          [
            (batch_init_helpers_EMPTY_NODE_STATE) EXCEPT
              !["messages"] =
                IF batch_init_helpers_sender_3055
                  /= batch_init_helpers_receiver_3053
                THEN batch_init_helpers_getMessages(batch_init_helpers_randomMessageIds_3057[
                  batch_init_helpers_sender_3055
                ])
                ELSE (batch_init_helpers_EMPTY_NODE_STATE)["messages"]
          ]
      ]
  ]

(*
  @type: (((Str -> Set(Str))) => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
*)
batch_init_helpers_initMessageStore(batch_init_helpers_randomMessageIds_3093) ==
  [
    batch_init_helpers_node_3091 \in batch_init_helpers_INIT_NODES |->
      batch_init_helpers_getMessages(batch_init_helpers_randomMessageIds_3093[
        batch_init_helpers_node_3091
      ])
  ]

(*
  @type: (() => Bool);
*)
step ==
  \E sender \in NODES:
    \E receiver \in { n_1585 \in NODES: n_1585 /= sender }:
      idle(sender, receiver)
        \/ addMessages(sender, receiver)
        \/ sendMessagesPayload(sender, receiver)
        \/ receiveMessagesPayload(sender, receiver)
        \/ storeReceivedMessages(sender, receiver)
        \/ determineAck(sender, receiver)
        \/ sendAckPayload(sender, receiver)
        \/ receiveAckPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
someReceiveAckPayload ==
  \E sender \in NODES:
    \E receiver \in { n_2028 \in NODES: n_2028 /= sender }:
      receiveAckPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
delivery_fairness ==
  \A sender_2564 \in NODES:
    \A receiver_2562 \in NODES:
      isPeerPair(sender_2564, receiver_2562)
        => WF_{payloadExchangeState}(addMessages(sender_2564, receiver_2562))
          /\ WF_{payloadExchangeState}(sendMessagesPayload(sender_2564, receiver_2562))
          /\ WF_{payloadExchangeState}(receiveMessagesPayload(sender_2564, receiver_2562))
          /\ WF_{payloadExchangeState}(storeReceivedMessages(sender_2564, receiver_2562))

(*
  @type: (() => Bool);
*)
acknowledgement_fairness ==
  \A sender_2596 \in NODES:
    \A receiver_2594 \in NODES:
      isPeerPair(sender_2596, receiver_2594)
        => WF_{payloadExchangeState}(determineAck(sender_2596, receiver_2594))
          /\ WF_{payloadExchangeState}(sendAckPayload(sender_2596, receiver_2594))
          /\ WF_{payloadExchangeState}(receiveAckPayload(sender_2596, receiver_2594))

(*
  @type: (() => Bool);
*)
receive_messages_payload_fairness ==
  WF_{payloadExchangeState}(someReceiveMessagesPayload)

(*
  @type: (() => Bool);
*)
determine_ack_fairness == WF_{payloadState}(someDetermineAck)

(*
  @type: (() => Bool);
*)
init ==
  nodeState = batch_init_helpers_initNodeState(RANDOM_MESSAGE_IDS)
    /\ payloadState = batch_init_helpers_initPayloadState
    /\ messageStore = batch_init_helpers_initMessageStore(RANDOM_MESSAGE_IDS)
    /\ payloadExchangeState = batch_init_helpers_initPayloadExchangeState

(*
  @type: (((Str -> Set(Str))) => Bool);
*)
initWithMessageIds(messageIds_1575) ==
  nodeState' := (batch_init_helpers_initNodeState(messageIds_1575))
    /\ payloadState' := (batch_init_helpers_initPayloadState)
    /\ messageStore' := (batch_init_helpers_initMessageStore(messageIds_1575))
    /\ payloadExchangeState' := (batch_init_helpers_initPayloadExchangeState)

(*
  @type: (() => Bool);
*)
receive_ack_payload_fairness == WF_{nodeState}(someReceiveAckPayload)

(*
  @type: (() => Bool);
*)
protocol_fairness ==
  (delivery_fairness /\ acknowledgement_fairness)
    /\ (\A sender_2525 \in NODES:
      \A receiver_2523 \in NODES:
        isPeerPair(sender_2525, receiver_2523)
          => WF_{payloadExchangeState}(idle(sender_2525, receiver_2523)))

(*
  @type: (() => Bool);
*)
pending_ack_is_eventually_cleared ==
  delivery_fairness /\ acknowledgement_fairness
    => (\A sender_2711 \in NODES:
      \A receiver_2709 \in NODES:
        isPeerPair(sender_2711, receiver_2709)
          => Cardinality((getPayloadAcks(payloadState, sender_2711, receiver_2709)))
            > 0
            ~> Cardinality((getPayloadAcks(payloadState, sender_2711, receiver_2709)))
              = 0)

(*
  @type: (() => Bool);
*)
acknowledged_messages_are_eventually_removed ==
  delivery_fairness /\ acknowledgement_fairness
    => (\A sender_2807 \in NODES:
      \A receiver_2805 \in NODES:
        isPeerPair(sender_2807, receiver_2805)
          => (\A id_2802 \in DOMAIN batch_init_helpers_MESSAGES:
            id_2802 \in getPayloadAcks(payloadState, sender_2807, receiver_2805)
              ~> ~(id_2802
                  \in getSetMessageIds((getNodeState(nodeState, sender_2807, receiver_2805))[
                    "messages"
                  ]))
                /\ ~(id_2802
                  \in payloadMessageIds((getPayload(payloadState, sender_2807, receiver_2805))))))

(*
  @type: (() => Bool);
*)
pending_messages_are_eventually_delivered ==
  delivery_fairness
    => (\A sender_2843 \in NODES:
      \A receiver_2841 \in NODES:
        isPeerPair(sender_2843, receiver_2841)
          => (\A id_2838 \in DOMAIN batch_init_helpers_MESSAGES:
            id_2838
              \in getSetMessageIds((getNodeState(nodeState, sender_2843, receiver_2841))[
                "messages"
              ])
              ~> id_2838
                \in getSetMessageIds((getMessagesMessageStore(messageStore, receiver_2841)))))

(*
  @type: (() => Bool);
*)
in_flight_payload_is_eventually_received ==
  receive_messages_payload_fairness
    => (\A sender_2638 \in NODES:
      \A receiver_2636 \in NODES:
        isPeerPair(sender_2638, receiver_2636)
          => hasInFlightMessagesPayload((getPayloadExchangeState(payloadExchangeState,
          sender_2638, receiver_2636)))
            ~> (getPayloadExchangeState(payloadExchangeState, sender_2638, receiver_2636))[
              "phase"
            ]
              = MessagesReceived)

(*
  @type: (() => Bool);
*)
pending_payload_is_eventually_acknowledged ==
  receive_messages_payload_fairness /\ determine_ack_fairness
    => (\A sender_2679 \in NODES:
      \A receiver_2677 \in NODES:
        isPeerPair(sender_2679, receiver_2677)
          => Cardinality((getPayloadMessages(payloadState, sender_2679, receiver_2677)))
              > 0
            /\ (getPayloadExchangeState(payloadExchangeState, sender_2679, receiver_2677))[
              "phase"
            ]
              = MessagesSent
            ~> Cardinality((getPayloadAcks(payloadState, sender_2679, receiver_2677)))
              > 0)

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
pending_messages_are_eventually_cleared ==
  protocol_fairness
    => (\A sender_2883 \in NODES:
      \A receiver_2881 \in NODES:
        isPeerPair(sender_2883, receiver_2881)
          => (\A id_2878 \in DOMAIN batch_init_helpers_MESSAGES:
            id_2878
              \in getSetMessageIds((getNodeState(nodeState, sender_2883, receiver_2881))[
                "messages"
              ])
              ~> ~(id_2878
                \in getSetMessageIds((getNodeState(nodeState, sender_2883, receiver_2881))[
                  "messages"
                ]))))

(*
  @type: (() => Bool);
*)
q_init == init

================================================================================
