# Introduction

The script [localisation.py](./localisation.py) has been created to test the computation of the healpix algorithm for determining specific pix indexes for given longitude and latitude coordinates. This is compared with the truncated of these coordinates to 3 decimals. This execution has been run 100 times per specific nside (resolution) to determine a statistical correct number. An example execution result can be found down below.

Note: this script needs to be run in a linux environment otherwise the `healpy` python package can't be used/installed.

# Requirements

- Linux OS or WSL (healpix python package only works in linux environments)
- Python
- Python packages describes in [requirements.txt](./requirements.txt)

# Commands to run

```bash
python3 -m venv .venv
. .venv/bin/activate
.venv/bin/python3 -m pip install -r requirements.txt # Only the first time
.venv/bin/python3 localisation.py
```

# Execution result

```bash
(.venv) xxx:~/localisation$ .venv/bin/python3 localisation.py
Enter latitude (-90 to 90):
No latitude input provided. Using default value: 52.239068
Enter longitude (-180 to 180):
No longitude input provided. Using default value: 6.850713

nside   pix_index    area      area      area         radius   radius   trunc_lat  trunc_lon  hp_time      gps_time     diff_time
(-)     (-)          (sr)      (deg²)    (km²)        (km)     (deg)    (deg)      (deg)      (ms) [100x]  (ms) [100x]  (ms) [100x]
-------------------------------------------------------------------------------------------------------------------------------------
2       4            0.261799  859.4367  10626343.16  1839.15  16.5399  52.239     6.850      0.0210       0.0015       0.0195
4       12           0.065450  214.8592  2656585.79   919.57   8.2699   52.239     6.850      0.0198       0.0015       0.0183
8       60           0.016362  53.7148   664146.45    459.79   4.1350   52.239     6.850      0.0196       0.0015       0.0181
16      264          0.004091  13.4287   166036.61    229.89   2.0675   52.239     6.850      0.0191       0.0016       0.0175
32      1201         0.001023  3.3572    41509.15     114.95   1.0337   52.239     6.850      0.0200       0.0015       0.0184
64      4903         0.000256  0.8393    10377.29     57.47    0.5169   52.239     6.850      0.0196       0.0015       0.0181
128     20207        0.000064  0.2098    2594.32      28.74    0.2584   52.239     6.850      0.0193       0.0015       0.0178
256     82027        0.000016  0.0525    648.58       14.37    0.1292   52.239     6.850      0.0211       0.0015       0.0196
512     327270       0.000004  0.0131    162.15       7.18     0.0646   52.239     6.850      0.0173       0.0013       0.0159
1024    1313881      0.000001  0.0033    40.54        3.59     0.0323   52.239     6.850      0.0149       0.0011       0.0138
2048    5265135      0.000000  0.0008    10.13        1.80     0.0162   52.239     6.850      0.0134       0.0010       0.0124
4096    21079771     0.000000  0.0002    2.53         0.90     0.0081   52.239     6.850      0.0117       0.0009       0.0108
8192    84331578     0.000000  0.0001    0.63         0.45     0.0040   52.239     6.850      0.0100       0.0007       0.0093
16384   337299352    0.000000  0.0000    0.16         0.22     0.0020   52.239     6.850      0.0095       0.0007       0.0088
32768   1349247381   0.000000  0.0000    0.04         0.11     0.0010   52.239     6.850      0.0086       0.0007       0.0079
65536   5396881678   0.000000  0.0000    0.01         0.06     0.0005   52.239     6.850      0.0078       0.0006       0.0072
131072  21587311020  0.000000  0.0000    0.00         0.03     0.0003   52.239     6.850      0.0077       0.0006       0.0071
-------------------------------------------------------------------------------------------------------------------------------------
```