--------------------------------- MODULE batch ---------------------------------

EXTENDS Integers, Sequences, FiniteSets, TLC, Apalache, Variants

(*
  @type: (() => None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }));
*)
Offer == Variant("Offer", [tag |-> "UNIT"])

VARIABLE
  (*
    @type: (Str -> (Str -> Bool));
  *)
  payloadSent

(*
  @type: (() => None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }));
*)
Request == Variant("Request", [tag |-> "UNIT"])

VARIABLE
  (*
    @type: (Str -> (Str -> Bool));
  *)
  payloadReceived

(*
  @type: (() => None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }));
*)
None == Variant("None", [tag |-> "UNIT"])

(*
  @type: ((Str, Str) => Bool);
*)
isPeerPair(sender_274, receiver_274) == sender_274 /= receiver_274

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
Idle == Variant("Idle", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
MessagesSent == Variant("MessagesSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
MessagesReceived == Variant("MessagesReceived", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
*)
AckSent == Variant("AckSent", [tag |-> "UNIT"])

(*
  @type: (() => AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }));
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
  @type: (() => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
*)
EMPTY_PAYLOAD ==
  [payloadId |-> 0,
    acks |-> {},
    offers |-> {},
    requests |-> {},
    messages |-> {}]

(*
  @type: ((Str, Str) => Bool);
*)
hasInFlightPayload(sender_1193, receiver_1193) ==
  payloadSent[sender_1193][receiver_1193]
    /\ ~(payloadReceived[receiver_1193][sender_1193])

(*
  @type: ((Str, Str) => Bool);
*)
canReceiveMessagesPayload(sender_422, receiver_422) ==
  (isPeerPair(sender_422, receiver_422) /\ payloadSent[sender_422][receiver_422])
    /\ ~(payloadReceived[receiver_422][sender_422])

(*
  @type: ((Str, Str) => Bool);
*)
canProcessDeliveredPayload(sender_444, receiver_444) ==
  (isPeerPair(sender_444, receiver_444) /\ payloadSent[sender_444][receiver_444])
    /\ payloadReceived[receiver_444][sender_444]

(*
  @type: (() => Set(Str));
*)
NODES == { (ALICE), (BOB) }

(*
  @type: (() => { messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) });
*)
EMPTY_RECORD_STATE == [messageId |-> "", recordType |-> None]

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
  @type: ((Str) => Bool);
*)
isDefaultNodeState(n_1093) ==
  (Cardinality(nodeState[n_1093][n_1093]["messages"]) = 0
      /\ Cardinality(nodeState[n_1093][n_1093]["offers"]) = 0)
    /\ Cardinality(nodeState[n_1093][n_1093]["requests"]) = 0

(*
  @type: ((Str, Str) => Bool);
*)
isDefaultPayloadState(sender_1153, receiver_1153) ==
  (((payloadState[sender_1153][receiver_1153]["payloadId"] = 0
          /\ Cardinality(payloadState[sender_1153][receiver_1153]["acks"]) = 0)
        /\ Cardinality(payloadState[sender_1153][receiver_1153]["offers"]) = 0)
      /\ Cardinality(payloadState[sender_1153][receiver_1153]["requests"]) = 0)
    /\ Cardinality(payloadState[sender_1153][receiver_1153]["messages"]) = 0

(*
  @type: ((Str, Str) => Set(Str));
*)
payloadMessageIds(sender_1174, receiver_1174) ==
  {
    m_1172["messageId"]:
      m_1172 \in payloadState[sender_1174][receiver_1174]["messages"]
  }

(*
  @type: ((Str, Str) => Bool);
*)
hasMessagesToProcess(sender_298, receiver_298) ==
  Cardinality(messageStore[sender_298]) /= 0
    /\ Cardinality(nodeState[sender_298][receiver_298]["messages"]) /= 0

(*
  @type: ((Str, Str) => Bool);
*)
hasSyncDelta(sender_321, receiver_321) ==
  \E m_319 \in nodeState[sender_321][receiver_321]["messages"]:
    ~(m_319 \in messageStore[receiver_321])

(*
  @type: ((Str, Str) => Bool);
*)
canSendMessagesPayload(sender_399, receiver_399) ==
  (((isPeerPair(sender_399, receiver_399)
          /\ Cardinality(payloadState[sender_399][receiver_399]["messages"])
            /= 0)
        /\ Cardinality(nodeState[sender_399][receiver_399]["messages"]) /= 0)
      /\ ~(payloadSent[sender_399][receiver_399]))
    /\ ~(payloadReceived[receiver_399][sender_399])

(*
  @type: ((Str, Str) => Bool);
*)
canReceiveAckPayload(sender_478, receiver_478) ==
  ((isPeerPair(sender_478, receiver_478)
        /\ Cardinality(payloadState[sender_478][receiver_478]["acks"]) /= 0)
      /\ payloadSent[receiver_478][sender_478])
    /\ ~(payloadReceived[sender_478][receiver_478])

(*
  @type: (() => Bool);
*)
two_nodes_only == Cardinality((NODES)) = 2

(*
  @type: (() => Bool);
*)
can_have_in_flight_payload ==
  \E sender_1525 \in NODES:
    \E receiver_1523 \in NODES:
      sender_1525 /= receiver_1523
        /\ hasInFlightPayload(sender_1525, receiver_1523)

(*
  @type: (() => Bool);
*)
can_have_delivered_payload ==
  \E sender_1566 \in NODES:
    \E receiver_1564 \in NODES:
      sender_1566 /= receiver_1564
        /\ payloadReceived[receiver_1564][sender_1566]

(*
  @type: ((Str) => { body: Str, groupId: Str, messageId: Str, timestamp: Int });
*)
getMessage(messageId_1817) == (MESSAGES)[messageId_1817]

(*
  @type: (() => (Str -> (Str -> Bool)));
*)
initPayloadSentState ==
  [ sender_223 \in NODES |-> [ receiver_221 \in NODES |-> FALSE ] ]

(*
  @type: (() => (Str -> (Str -> Bool)));
*)
initPayloadReceivedState ==
  [ sender_238 \in NODES |-> [ receiver_236 \in NODES |-> FALSE ] ]

(*
  @type: (() => (Str -> (Str -> AckReceived({ tag: Str }) | AckSent({ tag: Str }) | Idle({ tag: Str }) | MessagesReceived({ tag: Str }) | MessagesSent({ tag: Str }))));
*)
initPayloadExchangeState ==
  [ sender_253 \in NODES |-> [ receiver_251 \in NODES |-> Idle ] ]

(*
  @type: (() => Set(Set(Str)));
*)
getMessageIdsPowerset == SUBSET DOMAIN MESSAGES

(*
  @type: (() => Bool);
*)
pending_messages_belong_to_sender_store ==
  \A sender_1290 \in NODES:
    \A receiver_1288 \in NODES:
      sender_1290 /= receiver_1288
        => (\A m_1285 \in nodeState[sender_1290][receiver_1288]["messages"]:
          m_1285 \in messageStore[sender_1290])

(*
  @type: (() => Bool);
*)
pending_acks_imply_nonempty_payload ==
  \A sender_1344 \in NODES:
    \A receiver_1342 \in NODES:
      Cardinality(payloadState[sender_1344][receiver_1342]["acks"]) > 0
        => Cardinality(payloadState[sender_1344][receiver_1342]["messages"]) > 0

(*
  @type: (() => Bool);
*)
can_have_pending_messages ==
  \E sender_1486 \in NODES:
    \E receiver_1484 \in NODES:
      sender_1486 /= receiver_1484
        /\ Cardinality(nodeState[sender_1486][receiver_1484]["messages"]) > 0

(*
  @type: (() => Bool);
*)
can_have_payload_messages ==
  \E sender_1509 \in NODES:
    \E receiver_1507 \in NODES:
      sender_1509 /= receiver_1507
        /\ Cardinality(payloadState[sender_1509][receiver_1507]["messages"]) > 0

(*
  @type: (() => Bool);
*)
can_have_pending_acks ==
  \E sender_1548 \in NODES:
    \E receiver_1546 \in NODES:
      sender_1548 /= receiver_1546
        /\ Cardinality(payloadState[sender_1548][receiver_1546]["acks"]) > 0

(*
  @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
*)
initPayloadState ==
  [ sender_189 \in NODES |-> [ receiver_187 \in NODES |-> EMPTY_PAYLOAD ] ]

(*
  @type: ((Str, Str) => Bool);
*)
receiveMessagesPayload(sender_649, receiver_649) ==
  canReceiveMessagesPayload(sender_649, receiver_649)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadSent' := payloadSent
    /\ payloadReceived'
      := (LET (*
        @type: (() => (Str -> (Str -> Bool)));
      *)
      __quint_var2 == payloadReceived
      IN
      [
        (__quint_var2) EXCEPT
          ![receiver_649] =
            LET (*
              @type: (((Str -> Bool)) => (Str -> Bool));
            *)
            __QUINT_LAMBDA1(receiverState_644) ==
              LET (*
                @type: (() => (Str -> Bool));
              *)
              __quint_var1 == receiverState_644
              IN
              [
                (__quint_var1) EXCEPT
                  ![sender_649] =
                    LET (*
                      @type: ((Bool) => Bool);
                    *)
                    __QUINT_LAMBDA0(id__642) == TRUE
                    IN
                    __QUINT_LAMBDA0((__quint_var1)[sender_649])
              ]
            IN
            __QUINT_LAMBDA1((__quint_var2)[receiver_649])
      ])

(*
  @type: ((Str, Str) => Bool);
*)
storeReceivedMessages(sender_708, receiver_708) ==
  canProcessDeliveredPayload(sender_708, receiver_708)
    /\ messageStore'
      := (LET (*
        @type: (() => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
      *)
      __quint_var3 == messageStore
      IN
      [
        (__quint_var3) EXCEPT
          ![receiver_708] =
            LET (*
              @type: ((Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
            *)
            __QUINT_LAMBDA2(receiverStore_668) ==
              receiverStore_668
                \union payloadState[sender_708][receiver_708]["messages"]
            IN
            __QUINT_LAMBDA2((__quint_var3)[receiver_708])
      ])
    /\ nodeState'
      := (LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var5 == nodeState
      IN
      [
        (__quint_var5) EXCEPT
          ![receiver_708] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA4(receiverState_694) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var4 == receiverState_694
              IN
              [
                (__quint_var4) EXCEPT
                  ![sender_708] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA3(senderState_692) ==
                      [
                        senderState_692 EXCEPT
                          !["messages"] =
                            senderState_692["messages"]
                              \ payloadState[sender_708][receiver_708][
                                "messages"
                              ]
                      ]
                    IN
                    __QUINT_LAMBDA3((__quint_var4)[sender_708])
              ]
            IN
            __QUINT_LAMBDA4((__quint_var5)[receiver_708])
      ])
    /\ payloadState' := payloadState
    /\ payloadSent' := payloadSent
    /\ payloadReceived' := payloadReceived

(*
  @type: ((Str, Str) => Bool);
*)
determineAck(sender_752, receiver_752) ==
  canProcessDeliveredPayload(sender_752, receiver_752)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var7 == payloadState
      IN
      [
        (__quint_var7) EXCEPT
          ![sender_752] =
            LET (*
              @type: (((Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA6(senderPayload_741) ==
              LET (*
                @type: (() => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var6 == senderPayload_741
              IN
              [
                (__quint_var6) EXCEPT
                  ![receiver_752] =
                    LET (*
                      @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA5(receiverState_739) ==
                      [
                        receiverState_739 EXCEPT
                          !["acks"] =
                            {
                              m_735["messageId"]:
                                m_735 \in receiverState_739["messages"]
                            }
                      ]
                    IN
                    __QUINT_LAMBDA5((__quint_var6)[receiver_752])
              ]
            IN
            __QUINT_LAMBDA6((__quint_var7)[sender_752])
      ])
    /\ payloadSent' := payloadSent
    /\ payloadReceived' := payloadReceived

(*
  @type: ((Str, Str) => Bool);
*)
sendAckPayload(sender_815, receiver_815) ==
  canProcessDeliveredPayload(sender_815, receiver_815)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadSent'
      := (LET (*
        @type: (() => (Str -> (Str -> Bool)));
      *)
      __quint_var11 ==
        LET (*
          @type: (() => (Str -> (Str -> Bool)));
        *)
        __quint_var9 == payloadSent
        IN
        [
          (__quint_var9) EXCEPT
            ![receiver_815] =
              LET (*
                @type: (((Str -> Bool)) => (Str -> Bool));
              *)
              __QUINT_LAMBDA8(receiverState_777) ==
                LET (*
                  @type: (() => (Str -> Bool));
                *)
                __quint_var8 == receiverState_777
                IN
                [
                  (__quint_var8) EXCEPT
                    ![sender_815] =
                      LET (*
                        @type: ((Bool) => Bool);
                      *)
                      __QUINT_LAMBDA7(id__775) == TRUE
                      IN
                      __QUINT_LAMBDA7((__quint_var8)[sender_815])
                ]
              IN
              __QUINT_LAMBDA8((__quint_var9)[receiver_815])
        ]
      IN
      [
        (__quint_var11) EXCEPT
          ![sender_815] =
            LET (*
              @type: (((Str -> Bool)) => (Str -> Bool));
            *)
            __QUINT_LAMBDA10(senderState_787) ==
              LET (*
                @type: (() => (Str -> Bool));
              *)
              __quint_var10 == senderState_787
              IN
              [
                (__quint_var10) EXCEPT
                  ![receiver_815] =
                    LET (*
                      @type: ((Bool) => Bool);
                    *)
                    __QUINT_LAMBDA9(id__785) == FALSE
                    IN
                    __QUINT_LAMBDA9((__quint_var10)[receiver_815])
              ]
            IN
            __QUINT_LAMBDA10((__quint_var11)[sender_815])
      ])
    /\ payloadReceived'
      := (LET (*
        @type: (() => (Str -> (Str -> Bool)));
      *)
      __quint_var15 ==
        LET (*
          @type: (() => (Str -> (Str -> Bool)));
        *)
        __quint_var13 == payloadReceived
        IN
        [
          (__quint_var13) EXCEPT
            ![sender_815] =
              LET (*
                @type: (((Str -> Bool)) => (Str -> Bool));
              *)
              __QUINT_LAMBDA12(senderState_800) ==
                LET (*
                  @type: (() => (Str -> Bool));
                *)
                __quint_var12 == senderState_800
                IN
                [
                  (__quint_var12) EXCEPT
                    ![receiver_815] =
                      LET (*
                        @type: ((Bool) => Bool);
                      *)
                      __QUINT_LAMBDA11(id__798) == FALSE
                      IN
                      __QUINT_LAMBDA11((__quint_var12)[receiver_815])
                ]
              IN
              __QUINT_LAMBDA12((__quint_var13)[sender_815])
        ]
      IN
      [
        (__quint_var15) EXCEPT
          ![receiver_815] =
            LET (*
              @type: (((Str -> Bool)) => (Str -> Bool));
            *)
            __QUINT_LAMBDA14(receiverState_810) ==
              LET (*
                @type: (() => (Str -> Bool));
              *)
              __quint_var14 == receiverState_810
              IN
              [
                (__quint_var14) EXCEPT
                  ![sender_815] =
                    LET (*
                      @type: ((Bool) => Bool);
                    *)
                    __QUINT_LAMBDA13(id__808) == FALSE
                    IN
                    __QUINT_LAMBDA13((__quint_var14)[sender_815])
              ]
            IN
            __QUINT_LAMBDA14((__quint_var15)[receiver_815])
      ])

(*
  @type: (() => Bool);
*)
no_self_receiver_nodeState == \A n_1204 \in NODES: isDefaultNodeState(n_1204)

(*
  @type: (() => Bool);
*)
no_self_receiver_payloadState ==
  \A n_1212 \in NODES: isDefaultPayloadState(n_1212, n_1212)

(*
  @type: (() => Bool);
*)
no_reverse_payloadState ==
  \A sender_1262 \in NODES:
    \A receiver_1260 \in NODES:
      sender_1262 /= receiver_1260
        => (((~(payloadSent[sender_1262][receiver_1260])
                /\ ~(payloadReceived[receiver_1260][sender_1262]))
              /\ ~(payloadSent[receiver_1260][sender_1262]))
            /\ ~(payloadReceived[sender_1262][receiver_1260]))
          \/ (~(isDefaultPayloadState(sender_1262, receiver_1260))
            \/ ~(isDefaultPayloadState(receiver_1260, sender_1262)))

(*
  @type: (() => Bool);
*)
ack_ids_match_payload_messages ==
  \A sender_1314 \in NODES:
    \A receiver_1312 \in NODES:
      \A id_1310 \in payloadState[sender_1314][receiver_1312]["acks"]:
        id_1310 \in payloadMessageIds(sender_1314, receiver_1312)

(*
  @type: ((Str, Str) => Bool);
*)
canAddMessages(sender_353, receiver_353) ==
  (((isPeerPair(sender_353, receiver_353)
          /\ hasMessagesToProcess(sender_353, receiver_353))
        /\ hasSyncDelta(sender_353, receiver_353))
      /\ ~(payloadSent[sender_353][receiver_353]))
    /\ ~(payloadReceived[receiver_353][sender_353])

(*
  @type: ((Str, Str) => Bool);
*)
sendMessagesPayload(sender_616, receiver_616) ==
  canSendMessagesPayload(sender_616, receiver_616)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState' := payloadState
    /\ payloadSent'
      := (LET (*
        @type: (() => (Str -> (Str -> Bool)));
      *)
      __quint_var19 == payloadSent
      IN
      [
        (__quint_var19) EXCEPT
          ![sender_616] =
            LET (*
              @type: (((Str -> Bool)) => (Str -> Bool));
            *)
            __QUINT_LAMBDA16(senderState_608) ==
              LET (*
                @type: (() => (Str -> Bool));
              *)
              __quint_var18 == senderState_608
              IN
              [
                (__quint_var18) EXCEPT
                  ![receiver_616] =
                    LET (*
                      @type: ((Bool) => Bool);
                    *)
                    __QUINT_LAMBDA15(id__606) == TRUE
                    IN
                    __QUINT_LAMBDA15((__quint_var18)[receiver_616])
              ]
            IN
            __QUINT_LAMBDA16((__quint_var19)[sender_616])
      ])
    /\ payloadReceived' := payloadReceived

(*
  @type: ((Str, Str) => Bool);
*)
receiveAckPayload(sender_891, receiver_891) ==
  canReceiveAckPayload(sender_891, receiver_891)
    /\ messageStore' := messageStore
    /\ nodeState'
      := (LET (*
        @type: (() => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var21 == nodeState
      IN
      [
        (__quint_var21) EXCEPT
          ![sender_891] =
            LET (*
              @type: (((Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA18(senderState_854) ==
              LET (*
                @type: (() => (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var20 == senderState_854
              IN
              [
                (__quint_var20) EXCEPT
                  ![receiver_891] =
                    LET (*
                      @type: (({ messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA17(receiverState_852) ==
                      [
                        receiverState_852 EXCEPT
                          !["messages"] =
                            {
                              m_848 \in receiverState_852["messages"]:
                                ~(m_848["messageId"]
                                  \in payloadState[receiver_891][sender_891][
                                    "acks"
                                  ])
                            }
                      ]
                    IN
                    __QUINT_LAMBDA17((__quint_var20)[receiver_891])
              ]
            IN
            __QUINT_LAMBDA18((__quint_var21)[sender_891])
      ])
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var23 == payloadState
      IN
      [
        (__quint_var23) EXCEPT
          ![sender_891] =
            LET (*
              @type: (((Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA20(senderPayload_870) ==
              LET (*
                @type: (() => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var22 == senderPayload_870
              IN
              [
                (__quint_var22) EXCEPT
                  ![receiver_891] =
                    LET (*
                      @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA19(receiverState_868) ==
                      [ receiverState_868 EXCEPT !["acks"] = {} ]
                    IN
                    __QUINT_LAMBDA19((__quint_var22)[receiver_891])
              ]
            IN
            __QUINT_LAMBDA20((__quint_var23)[sender_891])
      ])
    /\ payloadSent' := payloadSent
    /\ payloadReceived'
      := (LET (*
        @type: (() => (Str -> (Str -> Bool)));
      *)
      __quint_var25 == payloadReceived
      IN
      [
        (__quint_var25) EXCEPT
          ![receiver_891] =
            LET (*
              @type: (((Str -> Bool)) => (Str -> Bool));
            *)
            __QUINT_LAMBDA22(receiverState_886) ==
              LET (*
                @type: (() => (Str -> Bool));
              *)
              __quint_var24 == receiverState_886
              IN
              [
                (__quint_var24) EXCEPT
                  ![sender_891] =
                    LET (*
                      @type: ((Bool) => Bool);
                    *)
                    __QUINT_LAMBDA21(id__884) == TRUE
                    IN
                    __QUINT_LAMBDA21((__quint_var24)[sender_891])
              ]
            IN
            __QUINT_LAMBDA22((__quint_var25)[receiver_891])
      ])

(*
  @type: ((Set(Str)) => Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }));
*)
getMessages(messageIds_1830) ==
  { getMessage(id_1828): id_1828 \in messageIds_1830 }

(*
  @type: (() => Set(Str));
*)
getRandomMessageIds == CHOOSE __quint_var0 \in getMessageIdsPowerset: TRUE

(*
  @type: (() => Bool);
*)
someReceiveMessagesPayload ==
  \E sender \in NODES:
    \E receiver \in { n_1012 \in NODES: n_1012 /= sender }:
      receiveMessagesPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
someDetermineAck ==
  \E sender \in NODES:
    \E receiver \in { n_1030 \in NODES: n_1030 /= sender }:
      determineAck(sender, receiver)

(*
  @type: (() => Bool);
*)
someReceiveAckPayload ==
  \E sender \in NODES:
    \E receiver \in { n_1048 \in NODES: n_1048 /= sender }:
      receiveAckPayload(sender, receiver)

(*
  @type: ((Str, Str) => Bool);
*)
addMessages(sender_583, receiver_583) ==
  canAddMessages(sender_583, receiver_583)
    /\ messageStore' := messageStore
    /\ nodeState' := nodeState
    /\ payloadState'
      := (LET (*
        @type: (() => (Str -> (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
      *)
      __quint_var29 == payloadState
      IN
      [
        (__quint_var29) EXCEPT
          ![sender_583] =
            LET (*
              @type: (((Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })) => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
            *)
            __QUINT_LAMBDA24(senderPayload_572) ==
              LET (*
                @type: (() => (Str -> { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }));
              *)
              __quint_var28 == senderPayload_572
              IN
              [
                (__quint_var28) EXCEPT
                  ![receiver_583] =
                    LET (*
                      @type: (({ acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) }) => { acks: Set(Str), messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), payloadId: Int, requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) });
                    *)
                    __QUINT_LAMBDA23(receiverPayload_570) ==
                      [
                        receiverPayload_570 EXCEPT
                          !["messages"] =
                            receiverPayload_570["messages"]
                              \union nodeState[sender_583][receiver_583][
                                "messages"
                              ]
                      ]
                    IN
                    __QUINT_LAMBDA23((__quint_var28)[receiver_583])
              ]
            IN
            __QUINT_LAMBDA24((__quint_var29)[sender_583])
      ])
    /\ payloadSent' := payloadSent
    /\ payloadReceived' := payloadReceived

(*
  @type: (((Str -> Set(Str))) => (Str -> Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int })));
*)
initMessageStore(randomMessageIds_209) ==
  [ node_207 \in NODES |-> getMessages(randomMessageIds_209[node_207]) ]

(*
  @type: (() => (Str -> Set(Str)));
*)
initRandomMessageIds == [ n_263 \in NODES |-> getRandomMessageIds ]

(*
  @type: (((Str -> Set(Str))) => (Str -> (Str -> { messages: Set({ body: Str, groupId: Str, messageId: Str, timestamp: Int }), offers: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }), requests: Set({ messageId: Str, recordType: None({ tag: Str }) | Offer({ tag: Str }) | Request({ tag: Str }) }) })));
*)
initNodeState(randomMessageIds_175) ==
  [
    sender_173 \in NODES |->
      [
        receiver_171 \in NODES |->
          [
            (EMPTY_NODE_STATE) EXCEPT
              !["messages"] =
                IF sender_173 /= receiver_171
                THEN getMessages(randomMessageIds_175[sender_173])
                ELSE (EMPTY_NODE_STATE)["messages"]
          ]
      ]
  ]

(*
  @type: (() => Bool);
*)
fair_receive_messages_payload ==
  WF_{payloadReceived}(someReceiveMessagesPayload)

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
step ==
  \E sender \in NODES:
    \E receiver \in { n_510 \in NODES: n_510 /= sender }:
      addMessages(sender, receiver)
        \/ sendMessagesPayload(sender, receiver)
        \/ receiveMessagesPayload(sender, receiver)
        \/ storeReceivedMessages(sender, receiver)
        \/ determineAck(sender, receiver)
        \/ sendAckPayload(sender, receiver)
        \/ receiveAckPayload(sender, receiver)

(*
  @type: (() => Bool);
*)
initWithoutMessagesToSyncTwoNodes ==
  LET (*
    @type: (() => Set(Str));
  *)
  bobIds ==
    CHOOSE __quint_var16 \in {
      s_959 \in SUBSET DOMAIN MESSAGES:
        Cardinality(s_959) > 0
    }:
      TRUE
  IN
  LET (*
    @type: (() => Set(Str));
  *)
  aliceIds ==
    CHOOSE __quint_var17 \in { s_970 \in SUBSET bobIds: Cardinality(s_970) > 0 }:
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
    /\ payloadSent' := (initPayloadSentState)
    /\ payloadReceived' := (initPayloadReceivedState)

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
    /\ payloadSent = initPayloadSentState
    /\ payloadReceived = initPayloadReceivedState

(*
  @type: (() => Bool);
*)
initWithMessagesToSyncTwoNodes ==
  LET (*
    @type: (() => Set(Str));
  *)
  aliceIds ==
    CHOOSE __quint_var26 \in {
      s_901 \in SUBSET DOMAIN MESSAGES:
        Cardinality(s_901) > 0
    }:
      TRUE
  IN
  LET (*
    @type: (() => Set(Str));
  *)
  bobIds ==
    CHOOSE __quint_var27 \in {
      s_917 \in SUBSET DOMAIN MESSAGES:
        \E id_915 \in aliceIds: ~(id_915 \in s_917)
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
    /\ payloadSent' := (initPayloadSentState)
    /\ payloadReceived' := (initPayloadReceivedState)

(*
  @type: (() => Bool);
*)
in_flight_payload_is_eventually_received ==
  fair_receive_messages_payload
    => (\A sender_1382 \in NODES:
      \A receiver_1380 \in NODES:
        sender_1382 /= receiver_1380
          => hasInFlightPayload(sender_1382, receiver_1380)
            ~> payloadReceived[receiver_1380][sender_1382])

(*
  @type: (() => Bool);
*)
pending_payload_is_eventually_acknowledged ==
  fair_receive_messages_payload /\ fair_determine_ack
    => (\A sender_1426 \in NODES:
      \A receiver_1424 \in NODES:
        sender_1426 /= receiver_1424
          => Cardinality(payloadState[sender_1426][receiver_1424]["messages"])
              > 0
            /\ payloadSent[sender_1426][receiver_1424]
            ~> Cardinality(payloadState[sender_1426][receiver_1424]["acks"]) > 0)

(*
  @type: (() => Bool);
*)
pending_ack_is_eventually_cleared ==
  fair_receive_ack_payload
    => (\A sender_1462 \in NODES:
      \A receiver_1460 \in NODES:
        sender_1462 /= receiver_1460
          => Cardinality(payloadState[sender_1462][receiver_1460]["acks"]) > 0
            ~> Cardinality(payloadState[sender_1462][receiver_1460]["acks"]) = 0)

(*
  @type: (() => Bool);
*)
q_step == step

(*
  @type: (() => Bool);
*)
q_init == init

================================================================================
