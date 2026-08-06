This document will explain the different version of the formal verification process.


| Version number | Description | What is included from the protocol? | What are the limitations? | What is assumed? | What commands to run? |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 00/bank | This is a test version to test out Quint as formal verification tool. [Documentation \| Quint Docs](https://quint.sh/docs) | - | - | - | <ul><br/><li>`quint run versions/00/bank/bank.qnt --invariant=no_negatives`</li><br/><li>`quint run versions/00/bank/bank.qnt --invariant=no_negatives --mbt`</li><br/><li>`cmd /c verify.cmd versions/00/bank/bank.qnt --invariant=no_negatives`</li><br/></ul> |
| 00/traffic_light | This is a test version to test out Quint as formal verification tool. | - | - | - | <ul><br/><li>`quint test versions/00/traffic_light/traffic_light.qnt --match greenYellowRedOrderTest` or with `python quint_runner.py versions/00/traffic_light/traffic_light.qnt`</li><br/></ul> |
| 01/batch | This is the basic implementation that uses the following design as start. [Minimum Viable Data Synchronization \| bigbrother-specs](https://status-im.github.io/bigbrother-specs/data_sync/mvds.html) | [Minimum Viable Data Synchronization \| bigbrother-specs](https://status-im.github.io/bigbrother-specs/data_sync/mvds.html)<br><br>The batch state is implemented. | <ul><li>Only 2 nodes present.</li><ul> | <ul><li>The transmission of messages is 100% reliable.</li><li>Only 2 nodes are present in the network.</li></ul> | <ul><br/><li>`python quint_runner.py  versions/01/batch/batch.qnt`</li><br/><li> > The run of invariants and temporal propositions can be run everything should pass.</li><br/></ul> |
| 01/interactive | This is the basic implementation that uses the following design as start. [Minimum Viable Data Synchronization \| bigbrother-specs](https://status-im.github.io/bigbrother-specs/data_sync/mvds.html) | [Minimum Viable Data Synchronization \| bigbrother-specs](https://status-im.github.io/bigbrother-specs/data_sync/mvds.html)<br><br>The interactive state is implemented. | <ul><li>Only 2 nodes present.</li><ul> | <ul><li>The transmission of messages is 100% reliable.</li><li>Only 2 nodes are present in the network.</li><ul> |  |





















