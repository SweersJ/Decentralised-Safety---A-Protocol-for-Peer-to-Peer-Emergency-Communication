from datetime import datetime
from os import path, makedirs

import healpy as hp
import pandas as pd
import matplotlib.pyplot as plt
from numpy import radians, floor, log2, mean, std, sqrt, pi
from time import perf_counter
from functools import wraps

def timed(func):
    @wraps(func)
    def wrapper(self, *args, **kwargs):
        start = perf_counter()
        result = func(self, *args, **kwargs)
        setattr(self, f"{func.__name__}_time", perf_counter() - start)
        return result
    return wrapper

def request_coordinates() -> tuple[float, float]:
    lat_input = input("Enter latitude in degrees (-90 to 90): ")
    print("")
    if lat_input != '':
        lat_input = float(lat_input)
    else:
        lat_input = 52.239068
        print(f"No latitude input provided. Using default value: {lat_input}\n")
    if lat_input < -90 or lat_input > 90:
        raise ValueError("Latitude must be between -90 and 90 degrees.")

    lon_input = input("Enter longitude in degrees (-180 to 180): ")
    print("")
    if lon_input != '':
        lon_input = float(lon_input)
    else:
        lon_input = 6.850713
        print(f"No longitude input provided. Using default value: {lon_input}\n")
    if lon_input < -180 or lon_input > 180:
        raise ValueError("Longitude must be between -180 and 180 degrees.")

    return lat_input, lon_input

class healpix:
    def __init__(self, print_output: bool = True) -> None:
        self.print_output = print_output

    def request_resolution(self) -> int:
        nside = input("Enter resolution (power of 2, e.g., 1, 2, 4, 8, ...): ")
        if nside != '':
            nside = int(nside)
        else:
            nside = 4096
        return nside

    @timed
    def get_pixel_index(self, nside: int, lat: float, lon: float) -> int:
        theta = radians(90 - lat)
        phi = radians(lon if lon >= 0 else lon + 360)
        return hp.ang2pix(nside, theta, phi, nest=False)

    @timed
    def get_pixel_area(self, nside: int) -> tuple[float, float, float, float, float]:
        pixel_area_sr = hp.nside2pixarea(nside, degrees=False)
        pixel_area_deg2 = hp.nside2pixarea(nside, degrees=True)
        EARTH_RADIUS_KM = 6371.0
        pixel_area_km2 = pixel_area_sr * EARTH_RADIUS_KM ** 2
        pixel_radius_km = sqrt(pixel_area_km2 / pi)
        pixel_radius_deg = sqrt(pixel_area_deg2 / pi)
        return pixel_area_sr, pixel_area_deg2, pixel_area_km2, pixel_radius_km, pixel_radius_deg
    
    def run(self, lat_input: float = None, lon_input: float = None, nside: int = None) -> tuple[int, float, float, float, float, float]:
        if lat_input is None or lon_input is None:
            lat_input, lon_input = request_coordinates()
        if nside is None:
            nside = self.request_resolution()
        pix = self.get_pixel_index(nside, lat_input, lon_input)
        pixel_area_sr, pixel_area_deg2, pixel_area_km2, pixel_radius_km, pixel_radius_deg = self.get_pixel_area(nside)

        if self.print_output:
            print(f"Pixel index: {pix}")
            print(f"Pixel area:   {pixel_area_sr:.6f} sr  ({pixel_area_deg2:.4f} deg²)  ({pixel_area_km2:.2f} km²)")
            print(f"Pixel radius: {pixel_radius_deg:.4f} deg  ({pixel_radius_km:.2f} km)")
            print(f"get_pixel_index took {self.get_pixel_index_time * 1000:.4f} ms")
            print(f"get_pixel_area took  {self.get_pixel_area_time * 1000:.4f} ms")
        
        return pix, pixel_area_sr, pixel_area_deg2, pixel_area_km2, pixel_radius_km, pixel_radius_deg

class gps_truncation:
    def __init__(self, print_output: bool = True) -> None:
        self.print_output = print_output

    @timed
    def truncate_coordinates(self, lat: float, lon: float, decimal_places: int = 3) -> tuple[float, float]:
        factor = 10 ** decimal_places
        truncated_lat = floor(lat * factor) / factor
        truncated_lon = floor(lon * factor) / factor
        return truncated_lat, truncated_lon

    def run(self, lat_input: float = None, lon_input: float = None) -> tuple[float, float]:
        if lat_input is None or lon_input is None:
            lat_input, lon_input = request_coordinates()
        truncated_lat, truncated_lon = self.truncate_coordinates(lat_input, lon_input)

        if self.print_output:
            print(f"Original coordinates:  Latitude: {lat_input}, Longitude: {lon_input}")
            print(f"Truncated coordinates: Latitude: {truncated_lat}, Longitude: {truncated_lon}")
            print(f"truncate_coordinates took {self.truncate_coordinates_time * 1000:.4f} ms")

        return truncated_lat, truncated_lon


def _build_table(lat_input: float, lon_input: float, hp_instance: healpix, gps_instance: gps_truncation, nside_values: list[int], num_runs: int = 100) -> pd.DataFrame:
    rows = []
    for nside in nside_values:
        run_hp, run_gps, run_diff = [], [], []
        for _ in range(num_runs):
            pix, pixel_area_sr, pixel_area_deg2, pixel_area_km2, pixel_radius_km, pixel_radius_deg = hp_instance.run(lat_input, lon_input, nside)
            trunc_lat, trunc_lon = gps_instance.run(lat_input, lon_input)
            run_hp.append(hp_instance.get_pixel_index_time * 1e6)
            run_gps.append(gps_instance.truncate_coordinates_time * 1e6)
            run_diff.append(abs(hp_instance.get_pixel_index_time - gps_instance.truncate_coordinates_time) * 1e6)
        rows.append({
            ("nside", "(-)"):         nside,
            ("pow", "(-)"):           int(log2(nside)),
            ("pix_index", "(-)"):     pix,
            ("area", "(sr)"):         pixel_area_sr,
            ("area", "(deg²)"):       pixel_area_deg2,
            ("area", "(km²)"):        pixel_area_km2,
            ("radius", "(km)"):       pixel_radius_km,
            ("radius", "(deg)"):      pixel_radius_deg,
            ("trunc_lat", "(deg)"):   trunc_lat,
            ("trunc_lon", "(deg)"):   trunc_lon,
            ("hp_time", f"mean (µs) [{num_runs}x]"): mean(run_hp),
            ("hp_time", f"std  (µs) [{num_runs}x]"): std(run_hp),
            ("gps_time", f"mean (µs) [{num_runs}x]"): mean(run_gps),
            ("gps_time", f"std  (µs) [{num_runs}x]"): std(run_gps),
            ("diff_time", f"mean (µs) [{num_runs}x]"): mean(run_diff),
            ("diff_time", f"std  (µs) [{num_runs}x]"): std(run_diff),
        })
    df = pd.DataFrame(rows)
    df.columns = pd.MultiIndex.from_tuples(df.columns)
    return df

def _print_table(df: pd.DataFrame) -> None:
    print(df.to_string(index=False, float_format=lambda x: f"{x:.4g}"))
    print("")

def _plot_table(df: pd.DataFrame, runs: int = 100) -> None:
    pow_vals = df[("pow", "(-)")]
    x_labels = [f"$2^{{{int(p)}}}$" for p in pow_vals]

    fig, ax = plt.subplots(figsize=(10, 5))
    fig.suptitle("HEALPix vs GPS truncation — timing vs nside", fontsize=13)

    # Timing (mean ± 1σ)
    for key, color, label in [
        ("hp_time",   "tab:blue",   "HEALPix"),
        ("gps_time",  "tab:orange", "GPS truncation"),
    ]:
        sub = df[key]
        mean_col = next(c for c in sub.columns if "mean" in c)
        std_col  = next(c for c in sub.columns if "std"  in c)
        m = sub[mean_col]
        s = sub[std_col]
        ax.plot(pow_vals, m, marker="o", color=color, label=label)
        ax.fill_between(pow_vals, m - s, m + s, color=color, alpha=0.2)
    ax.set_ylabel("Time (\u00b5s)")
    ax.set_title(f"Timing (mean \u00b1 1\u03c3) of {runs} runs")
    ax.legend()
    ax.grid(True, which="both", alpha=0.3)
    ax.set_xlabel("nside (2^n)")
    ax.set_xticks(pow_vals)
    ax.set_xticklabels(x_labels)

    plt.tight_layout()
    
    output_map = "figs"
    makedirs(output_map, exist_ok=True)
    filename = path.join(output_map, f'{datetime.now().strftime("%Y-%m-%d_%H-%M-%S")}_healpix_vs_gps_truncation_metrics.png')
    plt.savefig(filename, dpi=300)

def compare_increasing_nside(lat_input: float = None, lon_input: float = None) -> None:
    if lat_input is None or lon_input is None:
        lat_input, lon_input = request_coordinates()

    hp_instance = healpix(print_output=False)
    gps_instance = gps_truncation(print_output=False)

    nside_values = [2 ** i for i in range(1, 19)]  # 2, 4, 8, ..., 262144

    NUM_RUNS = 100
    df = _build_table(lat_input, lon_input, hp_instance, gps_instance, nside_values, num_runs=NUM_RUNS)
    _print_table(df)
    _plot_table(df, runs=NUM_RUNS)

def compare_fixed_nside(nside_power: int = 18, lat_input: float = None, lon_input: float = None) -> None:
    if lat_input is None or lon_input is None:
        lat_input, lon_input = request_coordinates()

    hp_instance = healpix(print_output=False)
    gps_instance = gps_truncation(print_output=False)

    nside = 2 ** nside_power

    NUM_RUNS = 100
    df = _build_table(lat_input, lon_input, hp_instance, gps_instance, [nside], num_runs=NUM_RUNS)
    _print_table(df)

if __name__ == "__main__":
    lat_input, lon_input = request_coordinates()
    compare_increasing_nside(lat_input, lon_input)
    # compare_fixed_nside(lat_input=lat_input, lon_input=lon_input)