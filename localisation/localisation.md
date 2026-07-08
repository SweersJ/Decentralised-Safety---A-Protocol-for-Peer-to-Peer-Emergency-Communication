# Introduction

The script [localisation.py](./localisation.py) has been created to test the computation of the HEALPix algorithm for determining specific pix indexes for given longitude and latitude coordinates. This is compared with the truncated of these coordinates to 3 decimals. This execution has been run 100 times per specific nside (resolution) to determine a statistical correct number. An example execution result can be found down below.

Note: this script needs to be run in a linux environment otherwise the `healpy` python package can't be used/installed.

# Requirements

- Linux OS or WSL (healpix python package only works in linux environments)
- Python
- Python packages describes in [requirements.txt](./requirements.txt)

# Commands to run

```bash
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -r requirements.txt # Only the first time
python3 localisation.py
```

# Execution result example

```bash
(.venv) xxx:xxx/localisation$ .venv/bin/python3 localisation.py
Enter latitude in degrees (-90 to 90): 

No latitude input provided. Using default value: 52.239068

Enter longitude in degrees (-180 to 180): 

No longitude input provided. Using default value: 6.850713

 nside pow   pix_index      area                      radius           trunc_lat trunc_lon           hp_time                            gps_time                           diff_time                  
   (-) (-)         (-)      (sr)    (deg²)     (km²)    (km)     (deg)     (deg)     (deg) mean (µs) [1000x] std  (µs) [1000x] mean (µs) [1000x] std  (µs) [1000x] mean (µs) [1000x] std  (µs) [1000x]
     2   1           4    0.2618     859.4 1.063e+07    1839     16.54     52.24      6.85             12.01             6.942            0.7697            0.4822             11.24             6.595
     4   2          12   0.06545     214.9 2.657e+06   919.6      8.27     52.24      6.85             7.995             4.266            0.5132            0.1144             7.482             4.186
     8   3          60   0.01636     53.71 6.641e+05   459.8     4.135     52.24      6.85             7.038            0.9693            0.4507           0.05877             6.587            0.9305
    16   4         264  0.004091     13.43  1.66e+05   229.9     2.067     52.24      6.85             7.589             2.136            0.4766             0.083             7.112             2.082
    32   5        1201  0.001023     3.357 4.151e+04   114.9     1.034     52.24      6.85             7.296             1.384            0.4707           0.08779             6.825             1.324
    64   6        4903 0.0002557    0.8393 1.038e+04   57.47    0.5169     52.24      6.85             8.084              1.15            0.5308            0.1962             7.553             1.123
   128   7       20207 6.392e-05    0.2098      2594   28.74    0.2584     52.24      6.85             8.174             1.254            0.5321           0.06874             7.642             1.203
   256   8       82027 1.598e-05   0.05246     648.6   14.37    0.1292     52.24      6.85             8.111            0.9465            0.5388            0.3131             7.577            0.9212
   512   9      327270 3.995e-06   0.01311     162.1   7.184   0.06461     52.24      6.85             7.788             1.259            0.5101           0.08462             7.278             1.202
  1024  10     1313881 9.987e-07  0.003278     40.54   3.592    0.0323     52.24      6.85             7.478             1.174            0.4887           0.09171             6.989             1.116
  2048  11     5265135 2.497e-07 0.0008196     10.13   1.796   0.01615     52.24      6.85             8.246              1.64            0.5609            0.2736             7.685             1.606
  4096  12    21079771 6.242e-08 0.0002049     2.534   0.898  0.008076     52.24      6.85              8.16             1.009            0.5489            0.3543             7.613             1.019
  8192  13    84331578  1.56e-08 5.123e-05    0.6334   0.449  0.004038     52.24      6.85             8.215             1.204            0.5307             0.109             7.684             1.146
 16384  14   337299352 3.901e-09 1.281e-05    0.1583  0.2245  0.002019     52.24      6.85             8.227             1.566            0.5356           0.07777             7.692              1.51
 32768  15  1349247381 9.753e-10 3.202e-06   0.03959  0.1123   0.00101     52.24      6.85             8.106            0.9027            0.5468            0.3076             7.561             0.904
 65536  16  5396881678 2.438e-10 8.004e-07  0.009897 0.05613 0.0005048     52.24      6.85             7.992             1.288            0.5349            0.3095             7.458              1.27
131072  17 21587311020 6.095e-11 2.001e-07  0.002474 0.02806 0.0002524     52.24      6.85             7.072            0.9313            0.4768            0.5342             6.616            0.9042
262144  18 86349643836 1.524e-11 5.003e-08 0.0006185 0.01403 0.0001262     52.24      6.85             7.111             1.048            0.4721           0.06821             6.639             1.009

Saved: exports/2026-07-06_18-57-24/summary.csv
Saved: exports/2026-07-06_18-57-24/raw.csv
Saved: exports/2026-07-06_18-57-24/healpix_vs_gps_truncation_metrics.png
Saved: exports/2026-07-06_18-57-24/scatter.png
```

