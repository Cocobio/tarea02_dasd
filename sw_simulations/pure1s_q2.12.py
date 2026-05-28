import random
import argparse


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Outputs a succession of 1s in Q2.12.")
    parser.add_argument("n", type=int, help="Length of sucession")

    return parser.parse_args()


def main() -> None:
    n = parse_arguments().n

    for _ in range(n):
        value = 1<<12
        print(f"{value:03X}")


if __name__ == "__main__":
    main()
