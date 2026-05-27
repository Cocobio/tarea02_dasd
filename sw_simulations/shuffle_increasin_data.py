import random
import argparse


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Creates a shuffled integer sucession of numbers")
    parser.add_argument("n", type=int, help="Length of sucession")

    return parser.parse_args()


def main() -> None:
    n = parse_arguments().n

    nums = [i for i in range(n)]
    random.shuffle(nums)

    for num in nums:
        print(f"{num:03X}")


if __name__ == "__main__":
    main()
