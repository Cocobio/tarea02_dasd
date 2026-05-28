def main() -> None:
    print('0000')
    for denom in range(9, 1024):
        value = round((1<<19)/denom)
        print(f"{value:04X}")


if __name__ == "__main__":
    main()
