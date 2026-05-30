import numpy as np
import argparse


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Creates a sinusoidal signal")
    parser.add_argument("n", type=int, nargs='?', default=100, help="Number of samples for mean and rms.")
    parser.add_argument("--results", action="store_true", help="Get mean and rms from the signal.")

    return parser.parse_args()


def main() -> None:
    x = np.linspace(0, 8*np.pi, 100)
    y = np.sin(x)
    y2 = y*0.7 + 0.8

    args = parse_arguments()
    n = args.n
    show_results = args.results

    if not show_results:
        for e in y2:
            value = round(e*2**12) # Set to QX.12
            print(f"{value:04X}")
    else:
        min = np.min(y2[:n])
        max = np.max(y2[:n])
        mean = np.mean(y2[:n])
        squared_mean = np.mean(y2[:n]**2)
        rms = np.sqrt(squared_mean)

        print(f"Min: {min}")
        print(f"Max: {max}")
        print(f"Mean: {mean}")
        print(f"RMS: {rms}")
        # print(f"Mean on square: {squared_mean}")


if __name__ == "__main__":
    main()
