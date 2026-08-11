--------------------------------- MODULE batch ---------------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }));
*)
Offer == Variant("Offer", [tag |-> "UNIT"])

(*
  @type: (() => None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }));
*)
Request == Variant("Request", [tag |-> "UNIT"])

(*
  @type: (() => None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }));
*)
None == Variant("None", [tag |-> "UNIT"])

(*
  @type: ((Str, Str) => Bool);
*)
isPeerPair(sender_257, receiver_257) == sender_257 /= receiver_257

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
Idle == Variant("Idle", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
MessagesAdded == Variant("MessagesAdded", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
MessagesSent == Variant("MessagesSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
MessagesReceived == Variant("MessagesReceived", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
AckSent == Variant("AckSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
AckReceived == Variant("AckReceived", [tag |-> "UNIT"])

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
    @type: (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
  *)
  messageStore

VARIABLE
  (*
    @type: (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) }));
  *)
  payloadExchangeState

(*
  @type: (((a -> b), a) => Bool);
*)
has(m_2670, key_2670) == key_2670 \in DOMAIN m_2670

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
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
message4 ==
  [messageId |->
      "f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e",
    groupId |-> "group-charlie",
    timestamp |-> 1751966400,
    body |-> "Road blocked at bridge"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
message5 ==
  [messageId |->
      "2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541",
    groupId |-> "group-charlie",
    timestamp |-> 1751966400,
    body |-> "Medic available at checkpoint"]

(*
  @type: (() => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
EMPTY_MESSAGE ==
  [messageId |-> "", groupId |-> "", timestamp |-> 0, body |-> ""]

(*
  @type: (() => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
*)
EMPTY_PAYLOAD ==
  [payloadId |-> 0,
    acks |-> {},
    offers |-> {},
    requests |-> {},
    messages |-> {}]

(*
  @type: (() => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
*)
EMPTY_NODE_STATE == [offers |-> {}, requests |-> {}, messages |-> {}]

VARIABLE
  (*
    @type: (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
  *)
  nodeState

VARIABLE
  (*
    @type: (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
  *)
  payloadState

(*
  @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set(Str));
*)
getSetMessageIds(messages_2368) ==
  { message_2366["messageId"]: message_2366 \in messages_2368 }

(*
  @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
excludeMessagesById(messages_2388, ids_2388) ==
  { message_2386 \in messages_2388: ~(message_2386["messageId"] \in ids_2388) }

(*
  @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
*)
EMPTY_PAYLOAD_EXCHANGE_STATE ==
  [phase |-> Idle, messagesStored |-> FALSE, ackDetermined |-> FALSE]

(*
  @type: (() => Set(Str));
*)
NODES == { (ALICE), (BOB) }

(*
  @type: (() => { messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) });
*)
EMPTY_RECORD_STATE == [messageId |-> "", recordType |-> None]

(*
  @type: (((c -> d), c, d) => d);
*)
getOrElse(m_2712, key_2712, default_2712) ==
  IF has(m_2712, key_2712) THEN m_2712[key_2712] ELSE default_2712

(*
  @type: (() => (Str -> { body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
MESSAGES ==
  SetAsFun({ <<(message1)["messageId"], (message1)>>,
    <<(message2)["messageId"], (message2)>>,
    <<(message3)["messageId"], (message3)>>,
    <<(message4)["messageId"], (message4)>>,
    <<(message5)["messageId"], (message5)>> })

(*
  @type: ((Str) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
getMessagesMessageStore(sender_500) == messageStore[sender_500]

(*
  @type: ((Str, Str) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
*)
getPayloadExchangeState(sender_536, receiver_536) ==
  payloadExchangeState[sender_536][receiver_536]

(*
  @type: ((Str, Str, AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }), Bool, Bool) => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) })));
*)
setPayloadExchangeState(sender_570, receiver_570, newPayloadExchangePhase_570, newMessagesStored_570,
newAckDetermined_570) ==
  LET (*
    @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) })));
  *)
  __quint_var2 == payloadExchangeState
  IN
  [
    (__quint_var2) EXCEPT
      ![sender_570] =
        LET (*
          @type: (((Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) })) => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) }));
        *)
        __QUINT_LAMBDA1(senderState_568) ==
          LET (*
            @type: (() => (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) }));
          *)
          __quint_var1 == senderState_568
          IN
          [
            (__quint_var1) EXCEPT
              ![receiver_570] =
                LET (*
                  @type: (({ ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) }) => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
                *)
                __QUINT_LAMBDA0(receiverState_566) ==
                  [phase |-> newPayloadExchangePhase_570,
                    messagesStored |-> newMessagesStored_570,
                    ackDetermined |-> newAckDetermined_570]
                IN
                __QUINT_LAMBDA0((__quint_var1)[receiver_570])
          ]
        IN
        __QUINT_LAMBDA1((__quint_var2)[sender_570])
  ]

(*
  @type: ((Str, Str) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
*)
getNodeState(sender_512, receiver_512) == nodeState[sender_512][receiver_512]

(*
  @type: ((Str, Str) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
*)
getPayload(sender_524, receiver_524) == payloadState[sender_524][receiver_524]

(*
  @type: (() => Bool);
*)
two_nodes_only == Cardinality((NODES)) = 2

(*
  @type: (() => Bool);
*)
messageStores_are_monotonic ==
  [][
    \A n_1605 \in NODES:
      messageStore[n_1605] \subseteq messageStore[n_1605]'
  ]_messageStore

(*
  @type: ((Str) => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
getMessage(messageId_2329) ==
  getOrElse((MESSAGES), messageId_2329, (EMPTY_MESSAGE))

(*
  @type: (() => (Str -> (Str -> { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) })));
*)
initPayloadExchangeState ==
  [
    sender_236 \in NODES |->
      [ receiver_234 \in NODES |-> EMPTY_PAYLOAD_EXCHANGE_STATE ]
  ]

(*
  @type: (() => Set(Set(Str)));
*)
getMessageIdsPowerset == SUBSET DOMAIN MESSAGES

(*
  @type: ((Str, Str) => Bool);
*)
hasInFlightPayload(sender_1304, receiver_1304) ==
  (getPayloadExchangeState(sender_1304, receiver_1304))["phase"] = MessagesSent

(*
  @type: (() => Bool);
*)
can_have_delivered_payload ==
  \E sender_2077 \in NODES:
    \E receiver_2075 \in NODES:
      isPeerPair(sender_2077, receiver_2075)
        /\ (getPayloadExchangeState(sender_2077, receiver_2075))["phase"]
          = MessagesReceived

(*
  @type: ((Str, Str) => Bool);
*)
canReceiveMessagesPayload(sender_358, receiver_358) ==
  isPeerPair(sender_358, receiver_358)
    /\ (getPayloadExchangeState(sender_358, receiver_358))["phase"]
      = MessagesSent

(*
  @type: ((Str, Str) => Bool);
*)
isDefaultPayloadExchangeState(sender_1276, receiver_1276) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
  *)
  payloadExchangeState_1275 ==
    getPayloadExchangeState(sender_1276, receiver_1276)
  IN
  ((payloadExchangeState_1275)["phase"] = Idle
      /\ ~((payloadExchangeState_1275)["messagesStored"]))
    /\ ~((payloadExchangeState_1275)["ackDetermined"])

(*
  @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
*)
initPayloadState ==
  [ sender_202 \in NODES |-> [ receiver_200 \in NODES |-> EMPTY_PAYLOAD ] ]

(*
  @type: ((Str, Str) => Bool);
*)
canStoreReceivedMessages(sender_384, receiver_384) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
  *)
  state == getPayloadExchangeState(sender_384, receiver_384)
  IN
  (isPeerPair(sender_384, receiver_384) /\ (state)["phase"] = MessagesReceived)
    /\ ~((state)["messagesStored"])

(*
  @type: ((Str, Str) => Bool);
*)
canDetermineAck(sender_410, receiver_410) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
  *)
  state == getPayloadExchangeState(sender_410, receiver_410)
  IN
  (isPeerPair(sender_410, receiver_410) /\ (state)["phase"] = MessagesReceived)
    /\ ~((state)["ackDetermined"])

(*
  @type: ((Str, Str) => Bool);
*)
canAckPayload(sender_439, receiver_439) ==
  LET (*
    @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
  *)
  state == getPayloadExchangeState(sender_439, receiver_439)
  IN
  ((isPeerPair(sender_439, receiver_439) /\ (state)["phase"] = MessagesReceived)
      /\ (state)["messagesStored"])
    /\ (state)["ackDetermined"]

(*
  @type: ((Str, Str) => Bool);
*)
canIdle(sender_491, receiver_491) ==
  LET (*
    @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
  *)
  phase == (getPayloadExchangeState(sender_491, receiver_491))["phase"]
  IN
  isPeerPair(sender_491, receiver_491) /\ (phase = Idle \/ phase = AckReceived)

(*
  @type: ((Str, Str) => Set(Str));
*)
payloadMessageIds(sender_1290, receiver_1290) ==
  getSetMessageIds((getPayload(sender_1290, receiver_1290))["messages"])

(*
  @type: (() => Bool);
*)
payload_messages_are_pending_or_known_by_receiver ==
  \A sender_1419 \in NODES:
    \A receiver_1417 \in NODES:
      isPeerPair(sender_1419, receiver_1417)
        => (\A m_1414 \in (getPayload(sender_1419, receiver_1417))["messages"]:
          m_1414 \in (getNodeState(sender_1419, receiver_1417))["messages"]
            \/ m_1414 \in getMessagesMessageStore(receiver_1417))

(*
  @type: (() => Bool);
*)
payload_messages_belong_to_sender ==
  \A sender_1444 \in NODES:
    \A receiver_1442 \in NODES:
      isPeerPair(sender_1444, receiver_1442)
        => (\A m_1439 \in (getPayload(sender_1444, receiver_1442))["messages"]:
          m_1439 \in getMessagesMessageStore(sender_1444))

(*
  @type: (() => Bool);
*)
pending_messages_belong_to_sender ==
  \A sender_1475 \in NODES:
    \A receiver_1473 \in NODES:
      isPeerPair(sender_1475, receiver_1473)
        => (\A m_1470 \in (getNodeState(sender_1475, receiver_1473))["messages"]:
          m_1470 \in getMessagesMessageStore(sender_1475))

(*
  @type: (() => Bool);
*)
sent_ack_ids_match_stored_messages ==
  \A sender_1532 \in NODES:
    \A receiver_1530 \in NODES:
      isPeerPair(sender_1532, receiver_1530)
        => ((getPayloadExchangeState(sender_1532, receiver_1530))["phase"]
          = AckSent
          => (\A id_1526 \in (getPayload(sender_1532, receiver_1530))["acks"]:
            id_1526 \in getSetMessageIds(messageStore[receiver_1530])))

(*
  @type: (() => Bool);
*)
pending_acks_imply_nonempty_payload ==
  \A sender_1564 \in NODES:
    \A receiver_1562 \in NODES:
      Cardinality((getPayload(sender_1564, receiver_1562))["acks"]) > 0
        => Cardinality((getPayload(sender_1564, receiver_1562))["messages"]) > 0

(*
  @type: (() => Bool);
*)
pending_message_id_removed_only_after_storage ==
  [](
    [
      \A sender_1766 \in NODES:
        \A receiver_1764 \in NODES:
          \A id_1761 \in DOMAIN MESSAGES:
            isPeerPair(sender_1766, receiver_1764)
              => (
                /\ id_1761
                     \in getSetMessageIds(
                       (nodeState[sender_1766][receiver_1764])["messages"]
                     )
                /\ id_1761
                     \notin getSetMessageIds(
                       (nodeState'[sender_1766][receiver_1764])["messages"]
                     )
                => id_1761
                     \in getSetMessageIds(
                       messageStore'[receiver_1764]
                     )
              )
    ]_<<nodeState, messageStore>>
  )


\* Orginal version
\* pending_message_id_removed_only_after_storage ==
\*   \A sender_1766 \in NODES:
\*     \A receiver_1764 \in NODES:
\*       isPeerPair(sender_1766, receiver_1764)
\*         => (\A id_1761 \in DOMAIN MESSAGES:
\*           [][id_1761
\*               \in getSetMessageIds((getNodeState(sender_1766, receiver_1764))[
\*                 "messages"
\*               ])
\*             /\ ~(id_1761
\*               \in getSetMessageIds((getNodeState(sender_1766, receiver_1764))[
\*                 "messages"
\*               ]))'
\*             => (id_1761
\*               \in getSetMessageIds((getMessagesMessageStore(receiver_1764))))']_<<nodeState, messageStore>>)

(*
  @type: (() => Bool);
*)
can_have_pending_messages ==
  \E sender_1999 \in NODES:
    \E receiver_1997 \in NODES:
      isPeerPair(sender_1999, receiver_1997)
        /\ Cardinality((getNodeState(sender_1999, receiver_1997))["messages"])
          > 0

(*
  @type: (() => Bool);
*)
can_have_payload_messages ==
  \E sender_2020 \in NODES:
    \E receiver_2018 \in NODES:
      isPeerPair(sender_2020, receiver_2018)
        /\ Cardinality((getPayload(sender_2020, receiver_2018))["messages"]) > 0

(*
  @type: (() => Bool);
*)
can_have_pending_acks ==
  \E sender_2057 \in NODES:
    \E receiver_2055 \in NODES:
      isPeerPair(sender_2057, receiver_2055)
        /\ Cardinality((getPayload(sender_2057, receiver_2055))["acks"]) > 0

(*
  @type: ((Str, Str) => Bool);
*)
hasSyncDelta(sender_278, receiver_278) ==
  Cardinality((getMessagesMessageStore(sender_278))) > 0
    /\ Cardinality((getNodeState(sender_278, receiver_278))["messages"]) > 0

(*
  @type: ((Str, Str) => Bool);
*)
canReceiveAckPayload(sender_466, receiver_466) ==
  (isPeerPair(sender_466, receiver_466)
      /\ Cardinality((getPayload(sender_466, receiver_466))["acks"]) /= 0)
    /\ (getPayloadExchangeState(sender_466, receiver_466))["phase"] = AckSent

(*
  @type: ((Str, Str) => Bool);
*)
isDefaultNodeState(sender_1204, receiver_1204) ==
  LET (*
    @type: (() => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
  *)
  nodeState_1203 == getNodeState(sender_1204, receiver_1204)
  IN
  (Cardinality((nodeState_1203)["messages"]) = 0
      /\ Cardinality((nodeState_1203)["offers"]) = 0)
    /\ Cardinality((nodeState_1203)["requests"]) = 0

(*
  @type: ((Str, Str) => Bool);
*)
isDefaultPayloadState(sender_1249, receiver_1249) ==
  LET (*
    @type: (() => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
  *)
  payload == getPayload(sender_1249, receiver_1249)
  IN
  ((((payload)["payloadId"] = 0 /\ Cardinality((payload)["acks"]) = 0)
        /\ Cardinality((payload)["offers"]) = 0)
      /\ Cardinality((payload)["requests"]) = 0)
    /\ Cardinality((payload)["messages"]) = 0

(*
  @type: ((Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
getMessages(messageIds_2342) ==
  { getMessage(id_2340): id_2340 \in messageIds_2342 }

(*
  @type: (() => Set(Str));
*)
getRandomMessageIds == CHOOSE __quint_var0 \in getMessageIdsPowerset: TRUE

(*
  @type: (() => Bool);
*)
can_have_in_flight_payload ==
  \E sender_2036 \in NODES:
    \E receiver_2034 \in NODES:
      isPeerPair(sender_2036, receiver_2034)
        /\ hasInFlightPayload(sender_2036, receiver_2034)

(*
  @type: ((Str, Str) => Bool);
*)
receiveMessagesPayload(sender_777, receiver_777) ==
  canReceiveMessagesPayload(sender_777, receiver_777)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_777, receiver_777)
      IN
      setPayloadExchangeState(sender_777, receiver_777, (MessagesReceived), (currentPayloadExchangeState)[
        "messagesStored"
      ], (currentPayloadExchangeState)["ackDetermined"]))

(*
  @type: (() => Bool);
*)
self_payloadExchangeState_is_always_empty ==
  \A n_1386 \in NODES: isDefaultPayloadExchangeState(n_1386, n_1386)

(*
  @type: ((Str, Str) => Bool);
*)
idle(sender_654, receiver_654) ==
  canIdle(sender_654, receiver_654)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (setPayloadExchangeState(sender_654, receiver_654, (Idle), FALSE, FALSE))

(*
  @type: ((Str, Str) => Bool);
*)
storeReceivedMessages(sender_844, receiver_844) ==
  canStoreReceivedMessages(sender_844, receiver_844)
    /\ messageStore'
      := (LET (*
        @type: (() => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
      *)
      __quint_var7 == messageStore
      IN
      [
        (__quint_var7) EXCEPT
          ![receiver_844] =
            LET (*
              @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
            *)
            __QUINT_LAMBDA2(receiverStore_794) ==
              receiverStore_794
                \union (getPayload(sender_844, receiver_844))["messages"]
            IN
            __QUINT_LAMBDA2((__quint_var7)[receiver_844])
      ])
    /\ nodeState'
      := (LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var9 == nodeState
      IN
      [
        (__quint_var9) EXCEPT
          ![receiver_844] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA4(receiverState_819) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var8 == receiverState_819
              IN
              [
                (__quint_var8) EXCEPT
                  ![sender_844] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA3(senderState_817) ==
                      [
                        senderState_817 EXCEPT
                          !["messages"] =
                            excludeMessagesById(senderState_817["messages"], (getSetMessageIds((getPayload(sender_844,
                            receiver_844))[
                              "messages"
                            ])))
                      ]
                    IN
                    __QUINT_LAMBDA3((__quint_var8)[sender_844])
              ]
            IN
            __QUINT_LAMBDA4((__quint_var9)[receiver_844])
      ])
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_844, receiver_844)
      IN
      setPayloadExchangeState(sender_844, receiver_844, (currentPayloadExchangeState)[
        "phase"
      ], TRUE, (currentPayloadExchangeState)["ackDetermined"]))

(*
  @type: ((Str, Str) => Bool);
*)
determineAck(sender_894, receiver_894) ==
  canDetermineAck(sender_894, receiver_894)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var11 == payloadState
      IN
      [
        (__quint_var11) EXCEPT
          ![sender_894] =
            LET (*
              @type: (((Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA6(senderPayload_872) ==
              LET (*
                @type: (() => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var10 == senderPayload_872
              IN
              [
                (__quint_var10) EXCEPT
                  ![receiver_894] =
                    LET (*
                      @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA5(receiverState_870) ==
                      [
                        receiverState_870 EXCEPT
                          !["acks"] =
                            getSetMessageIds(receiverState_870["messages"])
                      ]
                    IN
                    __QUINT_LAMBDA5((__quint_var10)[receiver_894])
              ]
            IN
            __QUINT_LAMBDA6((__quint_var11)[sender_894])
      ])
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_894, receiver_894)
      IN
      setPayloadExchangeState(sender_894, receiver_894, (currentPayloadExchangeState)[
        "phase"
      ], (currentPayloadExchangeState)["messagesStored"], TRUE))

(*
  @type: ((Str, Str) => Bool);
*)
sendAckPayload(sender_928, receiver_928) ==
  canAckPayload(sender_928, receiver_928)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_928, receiver_928)
      IN
      setPayloadExchangeState(sender_928, receiver_928, (AckSent), (currentPayloadExchangeState)[
        "messagesStored"
      ], (currentPayloadExchangeState)["ackDetermined"]))

(*
  @type: ((Str, Str) => Bool);
*)
receiveAckPayload(sender_1013, receiver_1013) ==
  canReceiveAckPayload(sender_1013, receiver_1013)
    /\ messageStore' := messageStore
    /\ nodeState'
      := (LET (*
        @type: (() => Set(Str));
      *)
      ackIds == (getPayload(sender_1013, receiver_1013))["acks"]
      IN
      LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var13 == nodeState
      IN
      [
        (__quint_var13) EXCEPT
          ![sender_1013] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA8(senderState_960) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var12 == senderState_960
              IN
              [
                (__quint_var12) EXCEPT
                  ![receiver_1013] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA7(receiverState_958) ==
                      [
                        receiverState_958 EXCEPT
                          !["messages"] =
                            excludeMessagesById(receiverState_958["messages"], (ackIds))
                      ]
                    IN
                    __QUINT_LAMBDA7((__quint_var12)[receiver_1013])
              ]
            IN
            __QUINT_LAMBDA8((__quint_var13)[sender_1013])
      ])
    /\ payloadState'
      := (LET (*
        @type: (() => Set(Str));
      *)
      ackIds == (getPayload(sender_1013, receiver_1013))["acks"]
      IN
      LET (*
        @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var15 == payloadState
      IN
      [
        (__quint_var15) EXCEPT
          ![sender_1013] =
            LET (*
              @type: (((Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA10(senderPayload_990) ==
              LET (*
                @type: (() => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var14 == senderPayload_990
              IN
              [
                (__quint_var14) EXCEPT
                  ![receiver_1013] =
                    LET (*
                      @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA9(receiverPayload_988) ==
                      [
                        [ receiverPayload_988 EXCEPT !["acks"] = {} ] EXCEPT
                          !["messages"] =
                            excludeMessagesById(receiverPayload_988["messages"],
                            (ackIds))
                      ]
                    IN
                    __QUINT_LAMBDA9((__quint_var14)[receiver_1013])
              ]
            IN
            __QUINT_LAMBDA10((__quint_var15)[sender_1013])
      ])
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_1013, receiver_1013)
      IN
      setPayloadExchangeState(sender_1013, receiver_1013, (AckReceived), (currentPayloadExchangeState)[
        "messagesStored"
      ], (currentPayloadExchangeState)["ackDetermined"]))

(*
  @type: (() => Bool);
*)
payload_message_invariant ==
  (payload_messages_are_pending_or_known_by_receiver
      /\ payload_messages_belong_to_sender)
    /\ pending_messages_belong_to_sender

(*
  @type: (() => Bool);
*)
ack_ids_match_payload_messages ==
  \A sender_1497 \in NODES:
    \A receiver_1495 \in NODES:
      \A id_1493 \in (getPayload(sender_1497, receiver_1495))["acks"]:
        id_1493 \in payloadMessageIds(sender_1497, receiver_1495)

(*
  @type: (() => Bool);
*)
determined_ack_covers_payload ==
  \A sender_1592 \in NODES:
    \A receiver_1590 \in NODES:
      isPeerPair(sender_1592, receiver_1590)
        => ((getPayloadExchangeState(sender_1592, receiver_1590))[
          "ackDetermined"
        ]
          => (getPayload(sender_1592, receiver_1590))["acks"]
            = payloadMessageIds(sender_1592, receiver_1590))

(*
  @type: ((Str, Str) => Bool);
*)
canAddMessages(sender_300, receiver_300) ==
  (isPeerPair(sender_300, receiver_300)
      /\ hasSyncDelta(sender_300, receiver_300))
    /\ (getPayloadExchangeState(sender_300, receiver_300))["phase"] = Idle

(*
  @type: ((Str, Str) => Bool);
*)
canSendMessagesPayload(sender_340, receiver_340) ==
  (((isPeerPair(sender_340, receiver_340)
          /\ hasSyncDelta(sender_340, receiver_340))
        /\ Cardinality((getPayload(sender_340, receiver_340))["messages"]) /= 0)
      /\ Cardinality((getNodeState(sender_340, receiver_340))["messages"]) /= 0)
    /\ (getPayloadExchangeState(sender_340, receiver_340))["phase"]
      = MessagesAdded

(*
  @type: (() => Bool);
*)
self_nodeState_is_always_empty ==
  \A n_1316 \in NODES: isDefaultNodeState(n_1316, n_1316)

(*
  @type: (() => Bool);
*)
self_payloadState_is_always_empty ==
  \A n_1324 \in NODES: isDefaultPayloadState(n_1324, n_1324)

(*
  @type: (() => Bool);
*)
reverse_payloadState_is_always_empty ==
  \A sender_1378 \in NODES:
    \A receiver_1376 \in NODES:
      isPeerPair(sender_1378, receiver_1376)
        => (((getPayloadExchangeState(sender_1378, receiver_1376))["phase"]
                = Idle
              \/ (getPayloadExchangeState(sender_1378, receiver_1376))["phase"]
                = AckReceived)
            /\ ((getPayloadExchangeState(receiver_1376, sender_1378))["phase"]
                = Idle
              \/ (getPayloadExchangeState(receiver_1376, sender_1378))["phase"]
                = AckReceived))
          \/ (~(isDefaultPayloadState(sender_1378, receiver_1376))
            \/ ~(isDefaultPayloadState(receiver_1376, sender_1378)))

(*
  @type: (((Str -> Set(Str))) => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
*)
initMessageStore(randomMessageIds_222) ==
  [ node_220 \in NODES |-> getMessages(randomMessageIds_222[node_220]) ]

(*
  @type: (() => (Str -> Set(Str)));
*)
initRandomMessageIds == [ n_246 \in NODES |-> getRandomMessageIds ]

(*
  @type: (((Str -> Set(Str))) => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
*)
initNodeState(randomMessageIds_188) ==
  [
    sender_186 \in NODES |->
      [
        receiver_184 \in NODES |->
          [
            (EMPTY_NODE_STATE) EXCEPT
              !["messages"] =
                IF sender_186 /= receiver_184
                THEN getMessages(randomMessageIds_188[sender_186])
                ELSE (EMPTY_NODE_STATE)["messages"]
          ]
      ]
  ]

(*
  @type: (() => Bool);
*)
someReceiveMessagesPayload ==
  \E sender \in NODES:
    \E receiver \in { n_1128 \in NODES: n_1128 /= sender }:
      receiveMessagesPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
someDetermineAck ==
  \E sender \in NODES:
    \E receiver \in { n_1146 \in NODES: n_1146 /= sender }:
      determineAck(sender, receiver)

(*
  @type: (() => Bool);
*)
someReceiveAckPayload ==
  \E sender \in NODES:
    \E receiver \in { n_1164 \in NODES: n_1164 /= sender }:
      receiveAckPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
sent_acks_are_sound ==
  (sent_ack_ids_match_stored_messages /\ ack_ids_match_payload_messages)
    /\ pending_acks_imply_nonempty_payload

(*
  @type: (() => Bool);
*)
acknowledgement_fairness ==
  \A sender_1978 \in NODES:
    \A receiver_1976 \in NODES:
      isPeerPair(sender_1978, receiver_1976)
        => (WF_{payloadExchangeState}(determineAck(sender_1978, receiver_1976))
            /\ WF_{payloadExchangeState}(sendAckPayload(sender_1978, receiver_1976)))
          /\ WF_{payloadExchangeState}(receiveAckPayload(sender_1978, receiver_1976))

(*
  @type: ((Str, Str) => Bool);
*)
addMessages(sender_709, receiver_709) ==
  canAddMessages(sender_709, receiver_709)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var17 == payloadState
      IN
      [
        (__quint_var17) EXCEPT
          ![sender_709] =
            LET (*
              @type: (((Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA12(senderPayload_687) ==
              LET (*
                @type: (() => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var16 == senderPayload_687
              IN
              [
                (__quint_var16) EXCEPT
                  ![receiver_709] =
                    LET (*
                      @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA11(receiverPayload_685) ==
                      [
                        receiverPayload_685 EXCEPT
                          !["messages"] =
                            receiverPayload_685["messages"]
                              \union (getNodeState(sender_709, receiver_709))[
                                "messages"
                              ]
                      ]
                    IN
                    __QUINT_LAMBDA11((__quint_var16)[receiver_709])
              ]
            IN
            __QUINT_LAMBDA12((__quint_var17)[sender_709])
      ])
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_709, receiver_709)
      IN
      setPayloadExchangeState(sender_709, receiver_709, (MessagesAdded), (currentPayloadExchangeState)[
        "messagesStored"
      ], (currentPayloadExchangeState)["ackDetermined"]))

(*
  @type: ((Str, Str) => Bool);
*)
sendMessagesPayload(sender_743, receiver_743) ==
  canSendMessagesPayload(sender_743, receiver_743)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadExchangeState'
      := (LET (*
        @type: (() => { ackDetermined: Bool, messagesStored: Bool, phase: AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesAdded({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }) });
      *)
      currentPayloadExchangeState ==
        getPayloadExchangeState(sender_743, receiver_743)
      IN
      setPayloadExchangeState(sender_743, receiver_743, (MessagesSent), (currentPayloadExchangeState)[
        "messagesStored"
      ], (currentPayloadExchangeState)["ackDetermined"]))

(*
  @type: (() => Bool);
*)
initWithMessagesToSyncTwoNodes ==
  LET (*
    @type: (() => Set(Str));
  *)
  aliceIds ==
    CHOOSE __quint_var3 \in {
      s_1023 \in SUBSET DOMAIN MESSAGES:
        Cardinality(s_1023) > 0
    }:
      TRUE
  IN
  LET (*
    @type: (() => Set(Str));
  *)
  bobIds ==
    CHOOSE __quint_var4 \in {
      s_1039 \in SUBSET DOMAIN MESSAGES:
        \E id_1037 \in aliceIds: ~(id_1037 \in s_1039)
    }:
      TRUE
  IN
  LET (*
    @type: (() => (Str -> Set(Str)));
  *)
  randomMessageIds == SetAsFun({ <<(ALICE), (aliceIds)>>, <<(BOB), (bobIds)>> })
  IN
  nodeState' := (initNodeState((randomMessageIds)))
    /\ payloadState' := (initPayloadState)
    /\ messageStore' := (initMessageStore((randomMessageIds)))
    /\ payloadExchangeState' := (initPayloadExchangeState)

(*
  @type: (() => Bool);
*)
initWithoutMessagesToSyncTwoNodes ==
  LET (*
    @type: (() => Set(Str));
  *)
  bobIds ==
    CHOOSE __quint_var5 \in {
      s_1078 \in SUBSET DOMAIN MESSAGES:
        Cardinality(s_1078) > 0
    }:
      TRUE
  IN
  LET (*
    @type: (() => Set(Str));
  *)
  aliceIds ==
    CHOOSE __quint_var6 \in {
      s_1089 \in SUBSET bobIds:
        Cardinality(s_1089) > 0
    }:
      TRUE
  IN
  LET (*
    @type: (() => (Str -> Set(Str)));
  *)
  randomMessageIds == SetAsFun({ <<(ALICE), (aliceIds)>>, <<(BOB), (bobIds)>> })
  IN
  nodeState' := (initNodeState((randomMessageIds)))
    /\ payloadState' := (initPayloadState)
    /\ messageStore' := (initMessageStore((randomMessageIds)))
    /\ payloadExchangeState' := (initPayloadExchangeState)

(*
  @type: (() => Bool);
*)
init ==
  LET (*
    @type: (() => (Str -> Set(Str)));
  *)
  randomMessageIds == initRandomMessageIds
  IN
  nodeState = initNodeState((randomMessageIds))
    /\ payloadState = initPayloadState
    /\ messageStore = initMessageStore((randomMessageIds))
    /\ payloadExchangeState = initPayloadExchangeState

(*
  @type: (() => Bool);
*)
fair_receive_messages_payload ==
  WF_{payloadExchangeState}(someReceiveMessagesPayload)

(*
  @type: (() => Bool);
*)
fair_determine_ack == WF_{payloadState}(someDetermineAck)

(*
  @type: (() => Bool);
*)
fair_receive_ack_payload == WF_{nodeState}(someReceiveAckPayload)

(*
  @type: (() => Bool);
*)
delivery_fairness ==
  \A sender_1945 \in NODES:
    \A receiver_1943 \in NODES:
      isPeerPair(sender_1945, receiver_1943)
        => ((WF_{payloadExchangeState}(addMessages(sender_1945, receiver_1943))
              /\ WF_{payloadExchangeState}(sendMessagesPayload(sender_1945, receiver_1943)))
            /\ WF_{payloadExchangeState}(receiveMessagesPayload(sender_1945, receiver_1943)))
          /\ WF_{payloadExchangeState}(storeReceivedMessages(sender_1945, receiver_1943))

(*
  @type: (() => Bool);
*)
step ==
  \E sender \in NODES:
    \E receiver \in { n_599 \in NODES: n_599 /= sender }:
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
in_flight_payload_is_eventually_received ==
  fair_receive_messages_payload
    => (\A sender_1646 \in NODES:
      \A receiver_1644 \in NODES:
        isPeerPair(sender_1646, receiver_1644)
          => hasInFlightPayload(sender_1646, receiver_1644)
            ~> (getPayloadExchangeState(sender_1646, receiver_1644))["phase"]
              = MessagesReceived)

(*
  @type: (() => Bool);
*)
pending_payload_is_eventually_acknowledged ==
  fair_receive_messages_payload /\ fair_determine_ack
    => (\A sender_1688 \in NODES:
      \A receiver_1686 \in NODES:
        isPeerPair(sender_1688, receiver_1686)
          => Cardinality((getPayload(sender_1688, receiver_1686))["messages"])
              > 0
            /\ (getPayloadExchangeState(sender_1688, receiver_1686))["phase"]
              = MessagesSent
            ~> Cardinality((getPayload(sender_1688, receiver_1686))["acks"]) > 0)

(*
  @type: (() => Bool);
*)
pending_ack_is_eventually_cleared ==
  fair_receive_ack_payload
    => (\A sender_1720 \in NODES:
      \A receiver_1718 \in NODES:
        isPeerPair(sender_1720, receiver_1718)
          => Cardinality((getPayload(sender_1720, receiver_1718))["acks"]) > 0
            ~> Cardinality((getPayload(sender_1720, receiver_1718))["acks"]) = 0)

(*
  @type: (() => Bool);
*)
acknowledged_messages_are_eventually_removed ==
  fair_receive_ack_payload
    => (\A sender_1809 \in NODES:
      \A receiver_1807 \in NODES:
        isPeerPair(sender_1809, receiver_1807)
          => (\A id_1804 \in DOMAIN MESSAGES:
            id_1804 \in (getPayload(sender_1809, receiver_1807))["acks"]
              ~> ~(id_1804
                  \in getSetMessageIds((getNodeState(sender_1809, receiver_1807))[
                    "messages"
                  ]))
                /\ ~(id_1804 \in payloadMessageIds(sender_1809, receiver_1807))))

(*
  @type: (() => Bool);
*)
pending_messages_are_eventually_delivered ==
  delivery_fairness
    => (\A sender_1843 \in NODES:
      \A receiver_1841 \in NODES:
        isPeerPair(sender_1843, receiver_1841)
          => (\A id_1838 \in DOMAIN MESSAGES:
            id_1838
              \in getSetMessageIds((getNodeState(sender_1843, receiver_1841))[
                "messages"
              ])
              ~> id_1838
                \in getSetMessageIds((getMessagesMessageStore(receiver_1841)))))

(*
  @type: (() => Bool);
*)
protocol_fairness ==
  (delivery_fairness /\ acknowledgement_fairness)
    /\ (\A sender_1904 \in NODES:
      \A receiver_1902 \in NODES:
        isPeerPair(sender_1904, receiver_1902)
          => WF_{payloadExchangeState}(idle(sender_1904, receiver_1902)))

(*
  @type: (() => Bool);
*)
q_init == init

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
pending_messages_are_eventually_cleared ==
  protocol_fairness
    => (\A sender_1881 \in NODES:
      \A receiver_1879 \in NODES:
        isPeerPair(sender_1881, receiver_1879)
          => (\A id_1876 \in DOMAIN MESSAGES:
            id_1876
              \in getSetMessageIds((getNodeState(sender_1881, receiver_1879))[
                "messages"
              ])
              ~> ~(id_1876
                \in getSetMessageIds((getNodeState(sender_1881, receiver_1879))[
                  "messages"
                ]))))

================================================================================

