# Introduction

This project provides several documents for example for the formal verification setup of an emergency communication protocol for decentralised networks. Specifically the synchronisation of messages of the network where the nodes have intermittent connectivity. Therefore, messages are stored on the nodes and synced when possible. Furthermore, the messages are given specific priorities to setup a reliable communication for several emergency communicators, such as emergency dispatchers and in-field emergency responders. Next to that civilians, will also be able to utilise the protocol, but with lower priorities.

The project is part of the Master thesis assignment, named 'Decentralised Safety: A Protocol for Peer-to-Peer Emergency Communication'

# Project structure

Formal verification of the protocol can be found in the folder [formal_verification](./formal_verification/) with its own [README.md](./formal_verification/README.md) file. Furthermore, other scripts can be found in this codebase for example the localisation tests that were executed.