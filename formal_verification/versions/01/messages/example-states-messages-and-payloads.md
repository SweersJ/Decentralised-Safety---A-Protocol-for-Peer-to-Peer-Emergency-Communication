```yml
m1:
  group_id: "group-alpha"
  timestamp: 1751966400
  body: "Need insulin at shelter A"
  message_id: 741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75

m2:
  group_id: "group-alpha"
  timestamp: 1751966465
  body: "Offer for 2L water near station"
  message_id: 12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c

m3:
  group_id: "group-bravo"
  timestamp: 1751966522
  body: "Request for flashlight batteries"
  message_id: 4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1

m4:
  group_id: "group-charlie"
  timestamp: 1751966588
  body: "Road blocked at bridge"
  message_id: f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e

m5:
  group_id: "group-charlie"
  timestamp: 1751966610
  body: "Medic available at checkpoint"
  message_id: 2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541
```

Payload 1:
```yml
acks: []
offers:
  - 741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75
  - 12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c
requests:
  - 4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1
messages:
  - group_id: "group-alpha"
    timestamp: 1751966400
    body: "Need insulin at shelter A"
  - group_id: "group-alpha"
    timestamp: 1751966465
    body: "Offer for 2L water near station"
```

Payload 2:
```yml
acks:
  - 741a51061e3b8351670ec7af7b1040710cb8adb4e34ef9528c1bc1f311cc9f75
offers:
  - 4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1
requests:
  - 12ab508965277ba7190d0833e0659ceae8a051cdedf21478cfa8eb785481e98c
messages:
  - group_id: "group-bravo"
    timestamp: 1751966522
    body: "Request for flashlight batteries"
```

Payload 3:
```yml
acks:
  - 4183701dda5d89fde3f72fea64dae70a78000b56e6f1c31c45cea54dd93208f1
offers:
  - f576172d148bd27bc56a66d62d5d6222914be28552da8ceba08727c25524ee9e
  - 2700c2ae2062a6b61de69659da7cb274c61237d2bca13ab2c9d732835ba71541
requests: []
messages:
  - group_id: "group-charlie"
    timestamp: 1751966588
    body: "Road blocked at bridge"
  - group_id: "group-charlie"
    timestamp: 1751966610
    body: "Medic available at checkpoint"
```