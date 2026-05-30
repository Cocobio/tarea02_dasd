def main() -> None:
    lut_addr_width = 6
    data_precission = 17
    for x in range(1<<lut_addr_width):
        width = data_precission-lut_addr_width-1 # 24 bits the whole data
        avr_val = (1<<data_precission-1) + (x << width) + (1<<width-1) - 1

        # U0.24
        aproximation = int(((avr_val*2**-data_precission)**-0.5) * 2**data_precission)

        print(f'{aproximation>>1:05X}')


if __name__ == "__main__":
    main()

