---------------------------- MODULE batch_two_nodes ----------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
message1 ==
  [messageId |->
      "741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75",
    groupId |-> "group-alpha",
    timestamp |-> 1751966400,
    body |-> "Need insulin at shelter A"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
message2 ==
  [messageId |->
      "12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c",
    groupId |-> "group-alpha",
    timestamp |-> 1751966400,
    body |-> "Offer: 2L water near station"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
message3 ==
  [messageId |->
      "4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1",
    groupId |-> "group-bravo",
    timestamp |-> 1751966400,
    body |-> "Request: flashlight batteries"]

(*
  @type: (() => Str);
*)
ALICE == "Alice"

(*
  @type: (() => Str);
*)
BOB == "Bob"

VARIABLE
  (*
    @type: (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
  *)
  batch_two_nodes_batch_nodeState

(*
  @type: (() => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
*)
batch_two_nodes_batch_batch_init_helpers_EMPTY_NODE_STATE ==
  [offers |-> {}, requests |-> {}, messages |-> {}]

(*
  @type: (((a -> b), a) => Bool);
*)
batch_two_nodes_batch_batch_init_helpers_has(batch_two_nodes_batch_batch_init_helpers_m_346,
batch_two_nodes_batch_batch_init_helpers_key_346) ==
  batch_two_nodes_batch_batch_init_helpers_key_346
    \in DOMAIN batch_two_nodes_batch_batch_init_helpers_m_346

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_message1 ==
  [messageId |->
      "741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75",
    groupId |-> "group-alpha",
    timestamp |-> 1751966400,
    body |-> "Need insulin at shelter A"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_message2 ==
  [messageId |->
      "12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c",
    groupId |-> "group-alpha",
    timestamp |-> 1751966400,
    body |-> "Offer: 2L water near station"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_message3 ==
  [messageId |->
      "4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1",
    groupId |-> "group-bravo",
    timestamp |-> 1751966400,
    body |-> "Request: flashlight batteries"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_message4 ==
  [messageId |->
      "f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e",
    groupId |-> "group-charlie",
    timestamp |-> 1751966400,
    body |-> "Road blocked at bridge"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_message5 ==
  [messageId |->
      "2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541",
    groupId |-> "group-charlie",
    timestamp |-> 1751966400,
    body |-> "Medic available at checkpoint"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_EMPTY_MESSAGE ==
  [messageId |-> "", groupId |-> "", timestamp |-> 0, body |-> ""]

VARIABLE
  (*
    @type: (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
  *)
  batch_two_nodes_batch_payloadState

(*
  @type: (() => None({ tag: Str }) | Some(f));
*)
batch_two_nodes_batch_batch_init_helpers_None ==
  Variant("None", [tag |-> "UNIT"])

VARIABLE
  (*
    @type: (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
  *)
  batch_two_nodes_batch_messageStore

VARIABLE
  (*
    @type: (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
  *)
  batch_two_nodes_batch_payloadExchangeState

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_batch_init_helpers_Idle ==
  Variant("Idle", [tag |-> "UNIT"])

(*
  @type: (((Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })), Str) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
getMessagesMessageStore(currentMessageStore_1035, node_1035) ==
  currentMessageStore_1035[node_1035]

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_3130, batch_two_nodes_batch_receiver_3130) ==
  batch_two_nodes_batch_sender_3130 /= batch_two_nodes_batch_receiver_3130

(*
  @type: (((Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })), Str) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_two_nodes_batch_getMessagesMessageStore(batch_two_nodes_batch_currentMessageStore_1035,
batch_two_nodes_batch_node_1035) ==
  batch_two_nodes_batch_currentMessageStore_1035[
    batch_two_nodes_batch_node_1035
  ]

(*
  @type: (((Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })), Str, Str) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
*)
batch_two_nodes_batch_getNodeState(batch_two_nodes_batch_currentNodeState_1053, batch_two_nodes_batch_sender_1053,
batch_two_nodes_batch_receiver_1053) ==
  batch_two_nodes_batch_currentNodeState_1053[batch_two_nodes_batch_sender_1053][
    batch_two_nodes_batch_receiver_1053
  ]

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
*)
batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_currentPayloadExchangeState_1217,
batch_two_nodes_batch_sender_1217, batch_two_nodes_batch_receiver_1217) ==
  batch_two_nodes_batch_currentPayloadExchangeState_1217[
    batch_two_nodes_batch_sender_1217
  ][
    batch_two_nodes_batch_receiver_1217
  ]

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_Idle == Variant("Idle", [tag |-> "UNIT"])

(*
  @type: ((h) => None({ tag: Str }) | Some(h));
*)
batch_two_nodes_batch_Some(batch_two_nodes_batch___SomeParam_248) ==
  Variant("Some", batch_two_nodes_batch___SomeParam_248)

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str })) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
batch_two_nodes_batch_setPayloadExchangeStatePhase(batch_two_nodes_batch_currentPayloadExchangeState_3173,
batch_two_nodes_batch_sender_3173, batch_two_nodes_batch_receiver_3173, batch_two_nodes_batch_newPayloadExchangePhase_3173) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var1 == batch_two_nodes_batch_currentPayloadExchangeState_3173
  IN
  [
    (__quint_var1) EXCEPT
      ![batch_two_nodes_batch_sender_3173] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA1(batch_two_nodes_batch_senderState_3171) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var0 == batch_two_nodes_batch_senderState_3171
          IN
          [
            (__quint_var0) EXCEPT
              ![batch_two_nodes_batch_receiver_3173] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA0(batch_two_nodes_batch_receiverState_3169) ==
                  [
                    batch_two_nodes_batch_receiverState_3169 EXCEPT
                      !["phase"] =
                        batch_two_nodes_batch_newPayloadExchangePhase_3173
                  ]
                IN
                __QUINT_LAMBDA0((__quint_var0)[
                  batch_two_nodes_batch_receiver_3173
                ])
          ]
        IN
        __QUINT_LAMBDA1((__quint_var1)[batch_two_nodes_batch_sender_3173])
  ]

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_MessagesAdded ==
  Variant("MessagesAdded", [tag |-> "UNIT"])

(*
  @type: (((Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), Str, Str) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
*)
batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1075,
batch_two_nodes_batch_sender_1075, batch_two_nodes_batch_receiver_1075) ==
  batch_two_nodes_batch_currentPayloadState_1075[
    batch_two_nodes_batch_sender_1075
  ][
    batch_two_nodes_batch_receiver_1075
  ]

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_MessagesSent == Variant("MessagesSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_MessagesReceived ==
  Variant("MessagesReceived", [tag |-> "UNIT"])

(*
  @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_two_nodes_batch_excludeMessagesById(batch_two_nodes_batch_messages_1012, batch_two_nodes_batch_ids_1012) ==
  {
    batch_two_nodes_batch_message_1010 \in batch_two_nodes_batch_messages_1012:
      ~(batch_two_nodes_batch_message_1010["messageId"]
        \in batch_two_nodes_batch_ids_1012)
  }

(*
  @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set(Str));
*)
batch_two_nodes_batch_getSetMessageIds(batch_two_nodes_batch_messages_992) ==
  {
    batch_two_nodes_batch_message_990["messageId"]:
      batch_two_nodes_batch_message_990 \in batch_two_nodes_batch_messages_992
  }

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
batch_two_nodes_batch_setPayloadExchangeStateMessagesStored(batch_two_nodes_batch_currentPayloadExchangeState_3239,
batch_two_nodes_batch_sender_3239, batch_two_nodes_batch_receiver_3239, batch_two_nodes_batch_newMessagesStored_3239) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var5 == batch_two_nodes_batch_currentPayloadExchangeState_3239
  IN
  [
    (__quint_var5) EXCEPT
      ![batch_two_nodes_batch_sender_3239] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA9(batch_two_nodes_batch_senderState_3237) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var4 == batch_two_nodes_batch_senderState_3237
          IN
          [
            (__quint_var4) EXCEPT
              ![batch_two_nodes_batch_receiver_3239] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA8(batch_two_nodes_batch_receiverState_3235) ==
                  [
                    batch_two_nodes_batch_receiverState_3235 EXCEPT
                      !["messagesStored"] =
                        batch_two_nodes_batch_newMessagesStored_3239
                  ]
                IN
                __QUINT_LAMBDA8((__quint_var4)[
                  batch_two_nodes_batch_receiver_3239
                ])
          ]
        IN
        __QUINT_LAMBDA9((__quint_var5)[batch_two_nodes_batch_sender_3239])
  ]

(*
  @type: (() => None({ tag: Str }) | Some(i));
*)
batch_two_nodes_batch_None == Variant("None", [tag |-> "UNIT"])

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
batch_two_nodes_batch_setPayloadExchangeStateAckDetermined(batch_two_nodes_batch_currentPayloadExchangeState_3206,
batch_two_nodes_batch_sender_3206, batch_two_nodes_batch_receiver_3206, batch_two_nodes_batch_newAckDetermined_3206) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var10 == batch_two_nodes_batch_currentPayloadExchangeState_3206
  IN
  [
    (__quint_var10) EXCEPT
      ![batch_two_nodes_batch_sender_3206] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA14(batch_two_nodes_batch_senderState_3204) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var9 == batch_two_nodes_batch_senderState_3204
          IN
          [
            (__quint_var9) EXCEPT
              ![batch_two_nodes_batch_receiver_3206] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA13(batch_two_nodes_batch_receiverState_3202) ==
                  [
                    batch_two_nodes_batch_receiverState_3202 EXCEPT
                      !["ackDetermined"] =
                        batch_two_nodes_batch_newAckDetermined_3206
                  ]
                IN
                __QUINT_LAMBDA13((__quint_var9)[
                  batch_two_nodes_batch_receiver_3206
                ])
          ]
        IN
        __QUINT_LAMBDA14((__quint_var10)[batch_two_nodes_batch_sender_3206])
  ]

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_AckSent == Variant("AckSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
*)
batch_two_nodes_batch_AckReceived == Variant("AckReceived", [tag |-> "UNIT"])

(*
  @type: (((Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })), Str, Str, AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }), Bool, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
batch_two_nodes_batch_setPayloadExchangeState(batch_two_nodes_batch_currentPayloadExchangeState_3279,
batch_two_nodes_batch_sender_3279, batch_two_nodes_batch_receiver_3279, batch_two_nodes_batch_newPayloadExchangePhase_3279,
batch_two_nodes_batch_newMessagesStored_3279, batch_two_nodes_batch_newAckDetermined_3279) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
  *)
  __quint_var18 == batch_two_nodes_batch_currentPayloadExchangeState_3279
  IN
  [
    (__quint_var18) EXCEPT
      ![batch_two_nodes_batch_sender_3279] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA28(batch_two_nodes_batch_senderState_3277) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }));
          *)
          __quint_var17 == batch_two_nodes_batch_senderState_3277
          IN
          [
            (__quint_var17) EXCEPT
              ![batch_two_nodes_batch_receiver_3279] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA27(batch_two_nodes_batch_receiverState_3275) ==
                  [phase |-> batch_two_nodes_batch_newPayloadExchangePhase_3279,
                    messagesStored |->
                      batch_two_nodes_batch_newMessagesStored_3279,
                    ackDetermined |->
                      batch_two_nodes_batch_newAckDetermined_3279]
                IN
                __QUINT_LAMBDA27((__quint_var17)[
                  batch_two_nodes_batch_receiver_3279
                ])
          ]
        IN
        __QUINT_LAMBDA28((__quint_var18)[batch_two_nodes_batch_sender_3279])
  ]

(*
  @type: (() => Set(Str));
*)
ALICE_MESSAGE_IDS == { (message1)["messageId"], (message2)["messageId"] }

(*
  @type: (() => Set(Str));
*)
BOB_MESSAGE_IDS == {(message3)["messageId"]}

(*
  @type: (() => (Str -> Set(Str)));
*)
MESSAGES_TO_SYNC_IDS ==
  SetAsFun({ <<(ALICE), {(message1)["messageId"]}>>,
    <<(BOB), {(message2)["messageId"]}>> })

(*
  @type: (() => (Str -> Set(Str)));
*)
MESSAGES_ALREADY_SYNCED_IDS ==
  SetAsFun({ <<(ALICE), {(message1)["messageId"]}>>,
    <<(BOB), { (message1)["messageId"], (message2)["messageId"] }>> })

(*
  @type: (() => Set(Str));
*)
TWO_NODES == { (ALICE), (BOB) }

(*
  @type: (((c -> d), c, d) => d);
*)
batch_two_nodes_batch_batch_init_helpers_getOrElse(batch_two_nodes_batch_batch_init_helpers_m_365,
batch_two_nodes_batch_batch_init_helpers_key_365, batch_two_nodes_batch_batch_init_helpers_default_365) ==
  IF batch_two_nodes_batch_batch_init_helpers_has(batch_two_nodes_batch_batch_init_helpers_m_365,
  batch_two_nodes_batch_batch_init_helpers_key_365)
  THEN batch_two_nodes_batch_batch_init_helpers_m_365[
    batch_two_nodes_batch_batch_init_helpers_key_365
  ]
  ELSE batch_two_nodes_batch_batch_init_helpers_default_365

(*
  @type: (() => (Str -> { body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_two_nodes_batch_batch_init_helpers_MESSAGES ==
  SetAsFun({ <<
      (batch_two_nodes_batch_batch_init_helpers_message1)["messageId"], (batch_two_nodes_batch_batch_init_helpers_message1)
    >>,
    <<
      (batch_two_nodes_batch_batch_init_helpers_message2)["messageId"], (batch_two_nodes_batch_batch_init_helpers_message2)
    >>,
    <<
      (batch_two_nodes_batch_batch_init_helpers_message3)["messageId"], (batch_two_nodes_batch_batch_init_helpers_message3)
    >>,
    <<
      (batch_two_nodes_batch_batch_init_helpers_message4)["messageId"], (batch_two_nodes_batch_batch_init_helpers_message4)
    >>,
    <<
      (batch_two_nodes_batch_batch_init_helpers_message5)["messageId"], (batch_two_nodes_batch_batch_init_helpers_message5)
    >> })

(*
  @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
*)
batch_two_nodes_batch_batch_init_helpers_EMPTY_PAYLOAD_EXCHANGE_STATE ==
  [phase |-> batch_two_nodes_batch_batch_init_helpers_Idle,
    messagesStored |-> FALSE,
    ackDetermined |-> FALSE]

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_hasSyncDelta(batch_two_nodes_batch_sender_1330, batch_two_nodes_batch_receiver_1330) ==
  Cardinality((batch_two_nodes_batch_getMessagesMessageStore(batch_two_nodes_batch_messageStore,
    batch_two_nodes_batch_sender_1330)))
      > 0
    /\ Cardinality((batch_two_nodes_batch_getNodeState(batch_two_nodes_batch_nodeState,
    batch_two_nodes_batch_sender_1330, batch_two_nodes_batch_receiver_1330))[
      "messages"
    ])
      > 0

(*
  @type: (((Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), Str, Str) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_two_nodes_batch_getPayloadMessages(batch_two_nodes_batch_currentPayloadState_1106,
batch_two_nodes_batch_sender_1106, batch_two_nodes_batch_receiver_1106) ==
  CASE VariantTag((batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1106,
    batch_two_nodes_batch_sender_1106, batch_two_nodes_batch_receiver_1106)))
      = "Some"
      -> LET (*
        @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
      *)
      __QUINT_LAMBDA6(batch_two_nodes_batch_payload_1101) ==
        batch_two_nodes_batch_payload_1101["messages"]
      IN
      __QUINT_LAMBDA6(VariantGetUnsafe("Some", (batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1106,
      batch_two_nodes_batch_sender_1106, batch_two_nodes_batch_receiver_1106))))
    [] VariantTag((batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1106,
    batch_two_nodes_batch_sender_1106, batch_two_nodes_batch_receiver_1106)))
      = "None"
      -> LET (*
        @type: (({ tag: Str }) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
      *)
      __QUINT_LAMBDA7(batch_two_nodes_batch___1104) == {}
      IN
      __QUINT_LAMBDA7(VariantGetUnsafe("None", (batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1106,
      batch_two_nodes_batch_sender_1106, batch_two_nodes_batch_receiver_1106))))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canReceiveMessagesPayload(batch_two_nodes_batch_sender_1409,
batch_two_nodes_batch_receiver_1409) ==
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1409, batch_two_nodes_batch_receiver_1409)
    /\ (batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1409, batch_two_nodes_batch_receiver_1409))[
      "phase"
    ]
      = batch_two_nodes_batch_MessagesSent

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canStoreReceivedMessages(batch_two_nodes_batch_sender_1435,
batch_two_nodes_batch_receiver_1435) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
  *)
  batch_two_nodes_batch_state ==
    batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1435, batch_two_nodes_batch_receiver_1435)
  IN
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1435, batch_two_nodes_batch_receiver_1435)
    /\ (batch_two_nodes_batch_state)["phase"]
      = batch_two_nodes_batch_MessagesReceived
    /\ ~((batch_two_nodes_batch_state)["messagesStored"])

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canDetermineAck(batch_two_nodes_batch_sender_1461, batch_two_nodes_batch_receiver_1461) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
  *)
  batch_two_nodes_batch_state ==
    batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1461, batch_two_nodes_batch_receiver_1461)
  IN
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1461, batch_two_nodes_batch_receiver_1461)
    /\ (batch_two_nodes_batch_state)["phase"]
      = batch_two_nodes_batch_MessagesReceived
    /\ ~((batch_two_nodes_batch_state)["ackDetermined"])

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canAckPayload(batch_two_nodes_batch_sender_1489, batch_two_nodes_batch_receiver_1489) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) });
  *)
  batch_two_nodes_batch_state ==
    batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1489, batch_two_nodes_batch_receiver_1489)
  IN
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1489, batch_two_nodes_batch_receiver_1489)
    /\ (batch_two_nodes_batch_state)["phase"]
      = batch_two_nodes_batch_MessagesReceived
    /\ (batch_two_nodes_batch_state)["messagesStored"]
    /\ (batch_two_nodes_batch_state)["ackDetermined"]

(*
  @type: (((Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))), Str, Str) => Set(Str));
*)
batch_two_nodes_batch_getPayloadAcks(batch_two_nodes_batch_currentPayloadState_1137,
batch_two_nodes_batch_sender_1137, batch_two_nodes_batch_receiver_1137) ==
  CASE VariantTag((batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1137,
    batch_two_nodes_batch_sender_1137, batch_two_nodes_batch_receiver_1137)))
      = "Some"
      -> LET (*
        @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => Set(Str));
      *)
      __QUINT_LAMBDA19(batch_two_nodes_batch_payload_1132) ==
        batch_two_nodes_batch_payload_1132["acks"]
      IN
      __QUINT_LAMBDA19(VariantGetUnsafe("Some", (batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1137,
      batch_two_nodes_batch_sender_1137, batch_two_nodes_batch_receiver_1137))))
    [] VariantTag((batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1137,
    batch_two_nodes_batch_sender_1137, batch_two_nodes_batch_receiver_1137)))
      = "None"
      -> LET (*
        @type: (({ tag: Str }) => Set(Str));
      *)
      __QUINT_LAMBDA20(batch_two_nodes_batch___1135) == {}
      IN
      __QUINT_LAMBDA20(VariantGetUnsafe("None", (batch_two_nodes_batch_getPayload(batch_two_nodes_batch_currentPayloadState_1137,
      batch_two_nodes_batch_sender_1137, batch_two_nodes_batch_receiver_1137))))

(*
  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) }) => Bool);
*)
batch_two_nodes_batch_hasInFlightMessagesPayload(batch_two_nodes_batch_state_3371) ==
  batch_two_nodes_batch_state_3371["phase"] = batch_two_nodes_batch_MessagesSent

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canIdle(batch_two_nodes_batch_sender_1541, batch_two_nodes_batch_receiver_1541) ==
  LET (*
    @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }));
  *)
  batch_two_nodes_batch_phase ==
    (batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1541, batch_two_nodes_batch_receiver_1541))[
      "phase"
    ]
  IN
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1541, batch_two_nodes_batch_receiver_1541)
    /\ (batch_two_nodes_batch_phase = batch_two_nodes_batch_Idle
      \/ batch_two_nodes_batch_phase = batch_two_nodes_batch_AckReceived)

(*
  @type: (() => (Str -> Set(Str)));
*)
TWO_NODE_MESSAGE_IDS ==
  SetAsFun({ <<(ALICE), (ALICE_MESSAGE_IDS)>>, <<(BOB), (BOB_MESSAGE_IDS)>> })

(*
  @type: (() => Set(Str));
*)
batch_two_nodes_batch_NODES == TWO_NODES

(*
  @type: ((Str) => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
batch_two_nodes_batch_batch_init_helpers_getMessage(batch_two_nodes_batch_batch_init_helpers_messageId_953) ==
  batch_two_nodes_batch_batch_init_helpers_getOrElse((batch_two_nodes_batch_batch_init_helpers_MESSAGES),
  batch_two_nodes_batch_batch_init_helpers_messageId_953, (batch_two_nodes_batch_batch_init_helpers_EMPTY_MESSAGE))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canAddMessages(batch_two_nodes_batch_sender_1352, batch_two_nodes_batch_receiver_1352) ==
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1352, batch_two_nodes_batch_receiver_1352)
    /\ batch_two_nodes_batch_hasSyncDelta(batch_two_nodes_batch_sender_1352, batch_two_nodes_batch_receiver_1352)
    /\ (batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1352, batch_two_nodes_batch_receiver_1352))[
      "phase"
    ]
      = batch_two_nodes_batch_Idle

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canSendMessagesPayload(batch_two_nodes_batch_sender_1390, batch_two_nodes_batch_receiver_1390) ==
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1390, batch_two_nodes_batch_receiver_1390)
    /\ batch_two_nodes_batch_hasSyncDelta(batch_two_nodes_batch_sender_1390, batch_two_nodes_batch_receiver_1390)
    /\ Cardinality((batch_two_nodes_batch_getPayloadMessages(batch_two_nodes_batch_payloadState,
    batch_two_nodes_batch_sender_1390, batch_two_nodes_batch_receiver_1390)))
      /= 0
    /\ Cardinality((batch_two_nodes_batch_getNodeState(batch_two_nodes_batch_nodeState,
    batch_two_nodes_batch_sender_1390, batch_two_nodes_batch_receiver_1390))[
      "messages"
    ])
      /= 0
    /\ (batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1390, batch_two_nodes_batch_receiver_1390))[
      "phase"
    ]
      = batch_two_nodes_batch_MessagesAdded

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_receiveMessagesPayload(batch_two_nodes_batch_sender_1761, batch_two_nodes_batch_receiver_1761) ==
  batch_two_nodes_batch_canReceiveMessagesPayload(batch_two_nodes_batch_sender_1761,
    batch_two_nodes_batch_receiver_1761)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState' := batch_two_nodes_batch_nodeState
    /\ batch_two_nodes_batch_payloadState' := batch_two_nodes_batch_payloadState
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStatePhase(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1761, batch_two_nodes_batch_receiver_1761, (batch_two_nodes_batch_MessagesReceived)))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_storeReceivedMessages(batch_two_nodes_batch_sender_1816, batch_two_nodes_batch_receiver_1816) ==
  batch_two_nodes_batch_canStoreReceivedMessages(batch_two_nodes_batch_sender_1816,
    batch_two_nodes_batch_receiver_1816)
    /\ batch_two_nodes_batch_messageStore'
      := (LET (*
        @type: (() => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
      *)
      __quint_var6 == batch_two_nodes_batch_messageStore
      IN
      [
        (__quint_var6) EXCEPT
          ![batch_two_nodes_batch_receiver_1816] =
            LET (*
              @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
            *)
            __QUINT_LAMBDA10(batch_two_nodes_batch_receiverStore_1777) ==
              batch_two_nodes_batch_receiverStore_1777
                \union batch_two_nodes_batch_getPayloadMessages(batch_two_nodes_batch_payloadState,
                batch_two_nodes_batch_sender_1816, batch_two_nodes_batch_receiver_1816)
            IN
            __QUINT_LAMBDA10((__quint_var6)[batch_two_nodes_batch_receiver_1816])
      ])
    /\ batch_two_nodes_batch_nodeState'
      := (LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })));
      *)
      __quint_var8 == batch_two_nodes_batch_nodeState
      IN
      [
        (__quint_var8) EXCEPT
          ![batch_two_nodes_batch_receiver_1816] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA12(batch_two_nodes_batch_receiverState_1801) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
              *)
              __quint_var7 == batch_two_nodes_batch_receiverState_1801
              IN
              [
                (__quint_var7) EXCEPT
                  ![batch_two_nodes_batch_sender_1816] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA11(batch_two_nodes_batch_senderState_1799) ==
                      [
                        batch_two_nodes_batch_senderState_1799 EXCEPT
                          !["messages"] =
                            batch_two_nodes_batch_excludeMessagesById(batch_two_nodes_batch_senderState_1799[
                              "messages"
                            ], (batch_two_nodes_batch_getSetMessageIds((batch_two_nodes_batch_getPayloadMessages(batch_two_nodes_batch_payloadState,
                            batch_two_nodes_batch_sender_1816, batch_two_nodes_batch_receiver_1816)))))
                      ]
                    IN
                    __QUINT_LAMBDA11((__quint_var7)[
                      batch_two_nodes_batch_sender_1816
                    ])
              ]
            IN
            __QUINT_LAMBDA12((__quint_var8)[batch_two_nodes_batch_receiver_1816])
      ])
    /\ batch_two_nodes_batch_payloadState' := batch_two_nodes_batch_payloadState
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStateMessagesStored(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1816, batch_two_nodes_batch_receiver_1816, TRUE))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_determineAck(batch_two_nodes_batch_sender_1866, batch_two_nodes_batch_receiver_1866) ==
  batch_two_nodes_batch_canDetermineAck(batch_two_nodes_batch_sender_1866, batch_two_nodes_batch_receiver_1866)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState' := batch_two_nodes_batch_nodeState
    /\ batch_two_nodes_batch_payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
      *)
      __quint_var12 == batch_two_nodes_batch_payloadState
      IN
      [
        (__quint_var12) EXCEPT
          ![batch_two_nodes_batch_sender_1866] =
            LET (*
              @type: (((Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))) => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
            *)
            __QUINT_LAMBDA18(batch_two_nodes_batch_senderPayload_1854) ==
              LET (*
                @type: (() => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
              *)
              __quint_var11 == batch_two_nodes_batch_senderPayload_1854
              IN
              [
                (__quint_var11) EXCEPT
                  ![batch_two_nodes_batch_receiver_1866] =
                    LET (*
                      @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                    *)
                    __QUINT_LAMBDA17(batch_two_nodes_batch_receiverPayload_1852) ==
                      CASE VariantTag(batch_two_nodes_batch_receiverPayload_1852)
                          = "Some"
                          -> LET (*
                            @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA15(batch_two_nodes_batch_payload_1847) ==
                            batch_two_nodes_batch_Some([
                              batch_two_nodes_batch_payload_1847 EXCEPT
                                !["acks"] =
                                  batch_two_nodes_batch_getSetMessageIds(batch_two_nodes_batch_payload_1847[
                                    "messages"
                                  ])
                            ])
                          IN
                          __QUINT_LAMBDA15(VariantGetUnsafe("Some", batch_two_nodes_batch_receiverPayload_1852))
                        [] VariantTag(batch_two_nodes_batch_receiverPayload_1852)
                          = "None"
                          -> LET (*
                            @type: (({ tag: Str }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA16(batch_two_nodes_batch___1850) ==
                            batch_two_nodes_batch_None
                          IN
                          __QUINT_LAMBDA16(VariantGetUnsafe("None", batch_two_nodes_batch_receiverPayload_1852))
                    IN
                    __QUINT_LAMBDA17((__quint_var11)[
                      batch_two_nodes_batch_receiver_1866
                    ])
              ]
            IN
            __QUINT_LAMBDA18((__quint_var12)[batch_two_nodes_batch_sender_1866])
      ])
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStateAckDetermined(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1866, batch_two_nodes_batch_receiver_1866, TRUE))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_sendAckPayload(batch_two_nodes_batch_sender_1890, batch_two_nodes_batch_receiver_1890) ==
  batch_two_nodes_batch_canAckPayload(batch_two_nodes_batch_sender_1890, batch_two_nodes_batch_receiver_1890)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState' := batch_two_nodes_batch_nodeState
    /\ batch_two_nodes_batch_payloadState' := batch_two_nodes_batch_payloadState
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStatePhase(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1890, batch_two_nodes_batch_receiver_1890, (batch_two_nodes_batch_AckSent)))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_canReceiveAckPayload(batch_two_nodes_batch_sender_1515, batch_two_nodes_batch_receiver_1515) ==
  batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_1515, batch_two_nodes_batch_receiver_1515)
    /\ Cardinality((batch_two_nodes_batch_getPayloadAcks(batch_two_nodes_batch_payloadState,
    batch_two_nodes_batch_sender_1515, batch_two_nodes_batch_receiver_1515)))
      /= 0
    /\ (batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
    batch_two_nodes_batch_sender_1515, batch_two_nodes_batch_receiver_1515))[
      "phase"
    ]
      = batch_two_nodes_batch_AckSent

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_idle(batch_two_nodes_batch_sender_1641, batch_two_nodes_batch_receiver_1641) ==
  batch_two_nodes_batch_canIdle(batch_two_nodes_batch_sender_1641, batch_two_nodes_batch_receiver_1641)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState' := batch_two_nodes_batch_nodeState
    /\ batch_two_nodes_batch_payloadState' := batch_two_nodes_batch_payloadState
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1641, batch_two_nodes_batch_receiver_1641, (batch_two_nodes_batch_Idle),
      FALSE, FALSE))

(*
  @type: (() => Set(Str));
*)
batch_two_nodes_batch_batch_init_helpers_INIT_NODES ==
  batch_two_nodes_batch_NODES

(*
  @type: ((Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
batch_two_nodes_batch_batch_init_helpers_getMessages(batch_two_nodes_batch_batch_init_helpers_messageIds_966) ==
  {
    batch_two_nodes_batch_batch_init_helpers_getMessage(batch_two_nodes_batch_batch_init_helpers_id_964):
      batch_two_nodes_batch_batch_init_helpers_id_964 \in
        batch_two_nodes_batch_batch_init_helpers_messageIds_966
  }

(*
  @type: (() => Bool);
*)
two_nodes_only == Cardinality((batch_two_nodes_batch_NODES)) = 2

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_addMessages(batch_two_nodes_batch_sender_1713, batch_two_nodes_batch_receiver_1713) ==
  batch_two_nodes_batch_canAddMessages(batch_two_nodes_batch_sender_1713, batch_two_nodes_batch_receiver_1713)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState' := batch_two_nodes_batch_nodeState
    /\ batch_two_nodes_batch_payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
      *)
      __quint_var3 == batch_two_nodes_batch_payloadState
      IN
      [
        (__quint_var3) EXCEPT
          ![batch_two_nodes_batch_sender_1713] =
            LET (*
              @type: (((Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))) => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
            *)
            __QUINT_LAMBDA5(batch_two_nodes_batch_senderPayload_1701) ==
              LET (*
                @type: (() => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
              *)
              __quint_var2 == batch_two_nodes_batch_senderPayload_1701
              IN
              [
                (__quint_var2) EXCEPT
                  ![batch_two_nodes_batch_receiver_1713] =
                    LET (*
                      @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                    *)
                    __QUINT_LAMBDA4(batch_two_nodes_batch_receiverPayload_1699) ==
                      CASE VariantTag(batch_two_nodes_batch_receiverPayload_1699)
                          = "None"
                          -> LET (*
                            @type: (({ tag: Str }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA2(batch_two_nodes_batch___1694) ==
                            batch_two_nodes_batch_Some([payloadId |-> 0,
                              offers |-> {},
                              requests |-> {},
                              acks |-> {},
                              messages |->
                                (batch_two_nodes_batch_getNodeState(batch_two_nodes_batch_nodeState,
                                batch_two_nodes_batch_sender_1713, batch_two_nodes_batch_receiver_1713))[
                                  "messages"
                                ]])
                          IN
                          __QUINT_LAMBDA2(VariantGetUnsafe("None", batch_two_nodes_batch_receiverPayload_1699))
                        [] VariantTag(batch_two_nodes_batch_receiverPayload_1699)
                          = "Some"
                          -> LET (*
                            @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA3(batch_two_nodes_batch_payload_1697) ==
                            batch_two_nodes_batch_Some([
                              batch_two_nodes_batch_payload_1697 EXCEPT
                                !["messages"] =
                                  batch_two_nodes_batch_payload_1697["messages"]
                                    \union (batch_two_nodes_batch_getNodeState(batch_two_nodes_batch_nodeState,
                                    batch_two_nodes_batch_sender_1713, batch_two_nodes_batch_receiver_1713))[
                                      "messages"
                                    ]
                            ])
                          IN
                          __QUINT_LAMBDA3(VariantGetUnsafe("Some", batch_two_nodes_batch_receiverPayload_1699))
                    IN
                    __QUINT_LAMBDA4((__quint_var2)[
                      batch_two_nodes_batch_receiver_1713
                    ])
              ]
            IN
            __QUINT_LAMBDA5((__quint_var3)[batch_two_nodes_batch_sender_1713])
      ])
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStatePhase(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1713, batch_two_nodes_batch_receiver_1713, (batch_two_nodes_batch_MessagesAdded)))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_sendMessagesPayload(batch_two_nodes_batch_sender_1737, batch_two_nodes_batch_receiver_1737) ==
  batch_two_nodes_batch_canSendMessagesPayload(batch_two_nodes_batch_sender_1737,
    batch_two_nodes_batch_receiver_1737)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState' := batch_two_nodes_batch_nodeState
    /\ batch_two_nodes_batch_payloadState' := batch_two_nodes_batch_payloadState
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStatePhase(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1737, batch_two_nodes_batch_receiver_1737, (batch_two_nodes_batch_MessagesSent)))

(*
  @type: ((Str, Str) => Bool);
*)
batch_two_nodes_batch_receiveAckPayload(batch_two_nodes_batch_sender_1982, batch_two_nodes_batch_receiver_1982) ==
  batch_two_nodes_batch_canReceiveAckPayload(batch_two_nodes_batch_sender_1982, batch_two_nodes_batch_receiver_1982)
    /\ batch_two_nodes_batch_messageStore' := batch_two_nodes_batch_messageStore
    /\ batch_two_nodes_batch_nodeState'
      := (LET (*
        @type: (() => Set(Str));
      *)
      batch_two_nodes_batch_ackIds ==
        batch_two_nodes_batch_getPayloadAcks(batch_two_nodes_batch_payloadState,
        batch_two_nodes_batch_sender_1982, batch_two_nodes_batch_receiver_1982)
      IN
      LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })));
      *)
      __quint_var14 == batch_two_nodes_batch_nodeState
      IN
      [
        (__quint_var14) EXCEPT
          ![batch_two_nodes_batch_sender_1982] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA22(batch_two_nodes_batch_senderState_1921) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }));
              *)
              __quint_var13 == batch_two_nodes_batch_senderState_1921
              IN
              [
                (__quint_var13) EXCEPT
                  ![batch_two_nodes_batch_receiver_1982] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA21(batch_two_nodes_batch_receiverState_1919) ==
                      [
                        batch_two_nodes_batch_receiverState_1919 EXCEPT
                          !["messages"] =
                            batch_two_nodes_batch_excludeMessagesById(batch_two_nodes_batch_receiverState_1919[
                              "messages"
                            ], (batch_two_nodes_batch_ackIds))
                      ]
                    IN
                    __QUINT_LAMBDA21((__quint_var13)[
                      batch_two_nodes_batch_receiver_1982
                    ])
              ]
            IN
            __QUINT_LAMBDA22((__quint_var14)[batch_two_nodes_batch_sender_1982])
      ])
    /\ batch_two_nodes_batch_payloadState'
      := (LET (*
        @type: (() => Set(Str));
      *)
      batch_two_nodes_batch_ackIds ==
        batch_two_nodes_batch_getPayloadAcks(batch_two_nodes_batch_payloadState,
        batch_two_nodes_batch_sender_1982, batch_two_nodes_batch_receiver_1982)
      IN
      LET (*
        @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
      *)
      __quint_var16 == batch_two_nodes_batch_payloadState
      IN
      [
        (__quint_var16) EXCEPT
          ![batch_two_nodes_batch_sender_1982] =
            LET (*
              @type: (((Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))) => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
            *)
            __QUINT_LAMBDA26(batch_two_nodes_batch_senderPayload_1969) ==
              LET (*
                @type: (() => (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })));
              *)
              __quint_var15 == batch_two_nodes_batch_senderPayload_1969
              IN
              [
                (__quint_var15) EXCEPT
                  ![batch_two_nodes_batch_receiver_1982] =
                    LET (*
                      @type: ((None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) })) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                    *)
                    __QUINT_LAMBDA25(batch_two_nodes_batch_receiverPayload_1967) ==
                      CASE VariantTag(batch_two_nodes_batch_receiverPayload_1967)
                          = "Some"
                          -> LET (*
                            @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA23(batch_two_nodes_batch_payload_1962) ==
                            LET (*
                              @type: (() => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
                            *)
                            batch_two_nodes_batch_remainingMessages ==
                              batch_two_nodes_batch_excludeMessagesById(batch_two_nodes_batch_payload_1962[
                                "messages"
                              ], (batch_two_nodes_batch_ackIds))
                            IN
                            IF Cardinality((batch_two_nodes_batch_remainingMessages))
                              = 0
                            THEN batch_two_nodes_batch_None
                            ELSE batch_two_nodes_batch_Some([
                              [
                                batch_two_nodes_batch_payload_1962 EXCEPT
                                  !["acks"] = {}
                              ] EXCEPT
                                !["messages"] =
                                  batch_two_nodes_batch_remainingMessages
                            ])
                          IN
                          __QUINT_LAMBDA23(VariantGetUnsafe("Some", batch_two_nodes_batch_receiverPayload_1967))
                        [] VariantTag(batch_two_nodes_batch_receiverPayload_1967)
                          = "None"
                          -> LET (*
                            @type: (({ tag: Str }) => None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }));
                          *)
                          __QUINT_LAMBDA24(batch_two_nodes_batch___1965) ==
                            batch_two_nodes_batch_None
                          IN
                          __QUINT_LAMBDA24(VariantGetUnsafe("None", batch_two_nodes_batch_receiverPayload_1967))
                    IN
                    __QUINT_LAMBDA25((__quint_var15)[
                      batch_two_nodes_batch_receiver_1982
                    ])
              ]
            IN
            __QUINT_LAMBDA26((__quint_var16)[batch_two_nodes_batch_sender_1982])
      ])
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_setPayloadExchangeStatePhase(batch_two_nodes_batch_payloadExchangeState,
      batch_two_nodes_batch_sender_1982, batch_two_nodes_batch_receiver_1982, (batch_two_nodes_batch_AckReceived)))

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_can_have_pending_messages ==
  \E batch_two_nodes_batch_sender_2906 \in batch_two_nodes_batch_NODES:
    \E batch_two_nodes_batch_receiver_2904 \in batch_two_nodes_batch_NODES:
      batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_2906, batch_two_nodes_batch_receiver_2904)
        /\ Cardinality((batch_two_nodes_batch_getNodeState(batch_two_nodes_batch_nodeState,
        batch_two_nodes_batch_sender_2906, batch_two_nodes_batch_receiver_2904))[
          "messages"
        ])
          > 0

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_can_have_payload_messages ==
  \E batch_two_nodes_batch_sender_2926 \in batch_two_nodes_batch_NODES:
    \E batch_two_nodes_batch_receiver_2924 \in batch_two_nodes_batch_NODES:
      batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_2926, batch_two_nodes_batch_receiver_2924)
        /\ Cardinality((batch_two_nodes_batch_getPayloadMessages(batch_two_nodes_batch_payloadState,
        batch_two_nodes_batch_sender_2926, batch_two_nodes_batch_receiver_2924)))
          > 0

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_can_have_in_flight_payload ==
  \E batch_two_nodes_batch_sender_2944 \in batch_two_nodes_batch_NODES:
    \E batch_two_nodes_batch_receiver_2942 \in batch_two_nodes_batch_NODES:
      batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_2944, batch_two_nodes_batch_receiver_2942)
        /\ batch_two_nodes_batch_hasInFlightMessagesPayload((batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
        batch_two_nodes_batch_sender_2944, batch_two_nodes_batch_receiver_2942)))

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_can_have_pending_acks ==
  \E batch_two_nodes_batch_sender_2964 \in batch_two_nodes_batch_NODES:
    \E batch_two_nodes_batch_receiver_2962 \in batch_two_nodes_batch_NODES:
      batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_2964, batch_two_nodes_batch_receiver_2962)
        /\ Cardinality((batch_two_nodes_batch_getPayloadAcks(batch_two_nodes_batch_payloadState,
        batch_two_nodes_batch_sender_2964, batch_two_nodes_batch_receiver_2962)))
          > 0

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_can_have_delivered_payload ==
  \E batch_two_nodes_batch_sender_2985 \in batch_two_nodes_batch_NODES:
    \E batch_two_nodes_batch_receiver_2983 \in batch_two_nodes_batch_NODES:
      batch_two_nodes_batch_isPeerPair(batch_two_nodes_batch_sender_2985, batch_two_nodes_batch_receiver_2983)
        /\ (batch_two_nodes_batch_getPayloadExchangeState(batch_two_nodes_batch_payloadExchangeState,
        batch_two_nodes_batch_sender_2985, batch_two_nodes_batch_receiver_2983))[
          "phase"
        ]
          = batch_two_nodes_batch_MessagesReceived

(*
  @type: (() => (Str -> Set(Str)));
*)
batch_two_nodes_batch_RANDOM_MESSAGE_IDS == TWO_NODE_MESSAGE_IDS

(*
  @type: (((Str -> Set(Str))) => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }), requests: Set({ messageId: Str, recordType: AckRecord({ tag: Str }) | MessageRecord({ tag: Str }) | OfferRecord({ tag: Str }) | RequestRecord({ tag: Str }) }) })));
*)
batch_two_nodes_batch_batch_init_helpers_initNodeState(batch_two_nodes_batch_batch_init_helpers_randomMessageIds_3057) ==
  [
    batch_two_nodes_batch_batch_init_helpers_sender_3055 \in
      batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
      [
        batch_two_nodes_batch_batch_init_helpers_receiver_3053 \in
          batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
          [
            (batch_two_nodes_batch_batch_init_helpers_EMPTY_NODE_STATE) EXCEPT
              !["messages"] =
                IF batch_two_nodes_batch_batch_init_helpers_sender_3055
                  /= batch_two_nodes_batch_batch_init_helpers_receiver_3053
                THEN batch_two_nodes_batch_batch_init_helpers_getMessages(batch_two_nodes_batch_batch_init_helpers_randomMessageIds_3057[
                  batch_two_nodes_batch_batch_init_helpers_sender_3055
                ])
                ELSE (batch_two_nodes_batch_batch_init_helpers_EMPTY_NODE_STATE)[
                  "messages"
                ]
          ]
      ]
  ]

(*
  @type: (() => (Str -> (Str -> None({ tag: Str }) | Some({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set(Str), payloadId: Int, requests: Set(Str) }))));
*)
batch_two_nodes_batch_batch_init_helpers_initPayloadState ==
  [
    batch_two_nodes_batch_batch_init_helpers___3073 \in
      batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
      [
        batch_two_nodes_batch_batch_init_helpers___3071 \in
          batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
          batch_two_nodes_batch_batch_init_helpers_None
      ]
  ]

(*
  @type: (((Str -> Set(Str))) => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
*)
batch_two_nodes_batch_batch_init_helpers_initMessageStore(batch_two_nodes_batch_batch_init_helpers_randomMessageIds_3093) ==
  [
    batch_two_nodes_batch_batch_init_helpers_node_3091 \in
      batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
      batch_two_nodes_batch_batch_init_helpers_getMessages(batch_two_nodes_batch_batch_init_helpers_randomMessageIds_3093[
        batch_two_nodes_batch_batch_init_helpers_node_3091
      ])
  ]

(*
  @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) | OffersAdded({ tag: Str }) | OffersReceived({ tag: Str }) | OffersSent({ tag: Str }) | RequestAdded({ tag: Str }) | RequestReceived({ tag: Str }) | RequestSent({ tag: Str }) })));
*)
batch_two_nodes_batch_batch_init_helpers_initPayloadExchangeState ==
  [
    batch_two_nodes_batch_batch_init_helpers_sender_3107 \in
      batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
      [
        batch_two_nodes_batch_batch_init_helpers_receiver_3105 \in
          batch_two_nodes_batch_batch_init_helpers_INIT_NODES |->
          batch_two_nodes_batch_batch_init_helpers_EMPTY_PAYLOAD_EXCHANGE_STATE
      ]
  ]

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_step ==
  \E batch_two_nodes_batch_sender \in batch_two_nodes_batch_NODES:
    \E batch_two_nodes_batch_receiver \in {
      batch_two_nodes_batch_n_1585 \in batch_two_nodes_batch_NODES:
        batch_two_nodes_batch_n_1585 /= batch_two_nodes_batch_sender
    }:
      batch_two_nodes_batch_idle(batch_two_nodes_batch_sender, batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_addMessages(batch_two_nodes_batch_sender, batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_sendMessagesPayload(batch_two_nodes_batch_sender,
        batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_receiveMessagesPayload(batch_two_nodes_batch_sender,
        batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_storeReceivedMessages(batch_two_nodes_batch_sender,
        batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_determineAck(batch_two_nodes_batch_sender, batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_sendAckPayload(batch_two_nodes_batch_sender, batch_two_nodes_batch_receiver)
        \/ batch_two_nodes_batch_receiveAckPayload(batch_two_nodes_batch_sender,
        batch_two_nodes_batch_receiver)

(*
  @type: (((Str -> Set(Str))) => Bool);
*)
batch_two_nodes_batch_initWithMessageIds(batch_two_nodes_batch_messageIds_1575) ==
  batch_two_nodes_batch_nodeState'
      := (batch_two_nodes_batch_batch_init_helpers_initNodeState(batch_two_nodes_batch_messageIds_1575))
    /\ batch_two_nodes_batch_payloadState'
      := (batch_two_nodes_batch_batch_init_helpers_initPayloadState)
    /\ batch_two_nodes_batch_messageStore'
      := (batch_two_nodes_batch_batch_init_helpers_initMessageStore(batch_two_nodes_batch_messageIds_1575))
    /\ batch_two_nodes_batch_payloadExchangeState'
      := (batch_two_nodes_batch_batch_init_helpers_initPayloadExchangeState)

(*
  @type: (() => Bool);
*)
batch_two_nodes_batch_init ==
  batch_two_nodes_batch_nodeState
      = batch_two_nodes_batch_batch_init_helpers_initNodeState((batch_two_nodes_batch_RANDOM_MESSAGE_IDS))
    /\ batch_two_nodes_batch_payloadState
      = batch_two_nodes_batch_batch_init_helpers_initPayloadState
    /\ batch_two_nodes_batch_messageStore
      = batch_two_nodes_batch_batch_init_helpers_initMessageStore((batch_two_nodes_batch_RANDOM_MESSAGE_IDS))
    /\ batch_two_nodes_batch_payloadExchangeState
      = batch_two_nodes_batch_batch_init_helpers_initPayloadExchangeState

(*
  @type: (() => Bool);
*)
q_step == batch_two_nodes_batch_step

(*
  @type: (() => Bool);
*)
initWithMessagesToSyncTwoNodes ==
  batch_two_nodes_batch_initWithMessageIds((MESSAGES_TO_SYNC_IDS))

(*
  @type: (() => Bool);
*)
initWithoutMessagesToSyncTwoNodes ==
  batch_two_nodes_batch_initWithMessageIds((MESSAGES_ALREADY_SYNCED_IDS))

(*
  @type: (() => Bool);
*)
q_init == batch_two_nodes_batch_init

================================================================================
