import healpy as hp # pyright: ignore[reportMissingImports]
from numpy import radians, floor, log2, mean, sqrt, pi
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

def request_coordinates():
    lat_input = input("Enter latitude in degrees (-90 to 90): ")
    if lat_input != '':
        lat_input = float(lat_input)
    else:
        lat_input = 52.239068
        print(f"No latitude input provided. Using default value: {lat_input}")
    if lat_input < -90 or lat_input > 90:
        raise ValueError("Latitude must be between -90 and 90 degrees.")

    lon_input = input("Enter longitude in degrees (-180 to 180): ")
    if lon_input != '':
        lon_input = float(lon_input)
    else:
        lon_input = 6.850713
        print(f"No longitude input provided. Using default value: {lon_input}")
    if lon_input < -180 or lon_input > 180:
        raise ValueError("Longitude must be between -180 and 180 degrees.")

    return lat_input, lon_input

class healpix:
    def __init__(self, print_output=True):
        self.print_output = print_output

    def request_resolution(self):
        nside = input("Enter resolution (power of 2, e.g., 1, 2, 4, 8, ...): ")
        if nside != '':
            nside = int(nside)
        else:
            nside = 4096
        return nside

    @timed
    def get_pixel_index(self, nside, lat, lon):
        theta = radians(90 - lat)
        phi = radians(lon if lon >= 0 else lon + 360)
        return hp.ang2pix(nside, theta, phi, nest=False)

    @timed
    def get_pixel_area(self, nside):
        pixel_area_sr = hp.nside2pixarea(nside, degrees=False)
        pixel_area_deg2 = hp.nside2pixarea(nside, degrees=True)
        EARTH_RADIUS_KM = 6371.0
        pixel_area_km2 = pixel_area_sr * EARTH_RADIUS_KM ** 2
        pixel_radius_km = sqrt(pixel_area_km2 / pi)
        pixel_radius_deg = sqrt(pixel_area_deg2 / pi)
        return pixel_area_sr, pixel_area_deg2, pixel_area_km2, pixel_radius_km, pixel_radius_deg
    
    def run(self, lat_input=None, lon_input=None, nside=None):
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
    def __init__(self, print_output=True):
        self.print_output = print_output

    @timed
    def truncate_coordinates(self, lat, lon, decimal_places=3):
        factor = 10 ** decimal_places
        truncated_lat = floor(lat * factor) / factor
        truncated_lon = floor(lon * factor) / factor
        return truncated_lat, truncated_lon

    def run(self, lat_input=None, lon_input=None):
        if lat_input is None or lon_input is None:
            lat_input, lon_input = request_coordinates()
        truncated_lat, truncated_lon = self.truncate_coordinates(lat_input, lon_input)

        if self.print_output:
            print(f"Original coordinates:  Latitude: {lat_input}, Longitude: {lon_input}")
            print(f"Truncated coordinates: Latitude: {truncated_lat}, Longitude: {truncated_lon}")
            print(f"truncate_coordinates took {self.truncate_coordinates_time * 1000:.4f} ms")

        return truncated_lat, truncated_lon


def _get_column_widths():
    widths = [7, 6, 12, 9, 9, 9, 9, 9, 10, 10, 12, 12, 13]
    return widths

def _get_formatted_table(lat_input, lon_input, hp_instance, gps_instance, nside_values, widths):
    NUM_RUNS = 100
    header1 = f"{'nside':<{widths[0]}} {'pow':<{widths[1]}} {'pix_index':<{widths[2]}} {'area':<{widths[3]}} {'area':<{widths[4]}} {'area':<{widths[5]}} {'radius':<{widths[6]}} {'radius':<{widths[7]}} {'trunc_lat':<{widths[8]}} {'trunc_lon':<{widths[9]}} {'hp_time':<{widths[10]}} {'gps_time':<{widths[11]}} {'diff_time':<{widths[12]}}"
    header2 = f"{'(-)':<{widths[0]}} {'(-)':<{widths[1]}} {'(-)':<{widths[2]}} {'(sr)':<{widths[3]}} {'(deg²)':<{widths[4]}} {'(km²)':<{widths[5]}} {'(km)':<{widths[6]}} {'(deg)':<{widths[7]}} {'(deg)':<{widths[8]}} {'(deg)':<{widths[9]}} {f'(µs) [{NUM_RUNS}x]':<{widths[10]}} {f'(µs) [{NUM_RUNS}x]':<{widths[11]}} {f'(µs) [{NUM_RUNS}x]':<{widths[12]}}"
    print(f"\n{header1}")
    print(f"{header2}")
    print("-" * len(header1))
    for nside in nside_values:
        run_hp, run_gps, run_diff = [], [], []
        for _ in range(NUM_RUNS):
            pix, pixel_area_sr, pixel_area_deg2, pixel_area_km2, pixel_radius_km, pixel_radius_deg = hp_instance.run(lat_input, lon_input, nside)
            trunc_lat, trunc_lon = gps_instance.run(lat_input, lon_input)
            run_hp.append(hp_instance.get_pixel_index_time * 1e6)
            run_gps.append(gps_instance.truncate_coordinates_time * 1e6)
            run_diff.append(abs(hp_instance.get_pixel_index_time - gps_instance.truncate_coordinates_time) * 1e6)
        avg_hp = mean(run_hp)
        avg_gps = mean(run_gps)
        avg_diff = mean(run_diff)
        nside_pow = int(log2(nside))
        print(f"{nside:<{widths[0]}} {nside_pow:<{widths[1]}} {pix:<{widths[2]}} {pixel_area_sr:<{widths[3]}.2e} {pixel_area_deg2:<{widths[4]}.2e} {pixel_area_km2:<{widths[5]}.2e} {pixel_radius_km:<{widths[6]}.2e} {pixel_radius_deg:<{widths[7]}.2e} {trunc_lat:<{widths[8]}.3f} {trunc_lon:<{widths[9]}.3f} {avg_hp:<{widths[10]}.2f} {avg_gps:<{widths[11]}.2f} {avg_diff:<{widths[12]}.2f}")
    print("-" * len(header1))

def compare_increasing_nside(lat_input=None, lon_input=None):
    if lat_input is None or lon_input is None:
        lat_input, lon_input = request_coordinates()

    hp_instance = healpix(print_output=False)
    gps_instance = gps_truncation(print_output=False)

    nside_values = [2 ** i for i in range(1, 19)]  # 2, 4, 8, ..., 262.144

    widths = _get_column_widths()

    _get_formatted_table(lat_input, lon_input, hp_instance, gps_instance, nside_values, widths)

def compare_fixed_nside(nside_power=18, lat_input=None, lon_input=None):
    if lat_input is None or lon_input is None:
        lat_input, lon_input = request_coordinates()

    hp_instance = healpix(print_output=False)
    gps_instance = gps_truncation(print_output=False)

    nside = 2 ** nside_power

    widths = _get_column_widths()
    
    _get_formatted_table(lat_input, lon_input, hp_instance, gps_instance, [nside], widths)

if __name__ == "__main__":
    lat_input, lon_input = request_coordinates()
    compare_increasing_nside(lat_input, lon_input)
    compare_fixed_nside(lat_input=lat_input, lon_input=lon_input)