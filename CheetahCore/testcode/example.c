int main(){
    volatile int a = 1;
    volatile int b = 2;
    volatile int c = a + b;

    volatile int ints[5];
    volatile short shorts[5];
    volatile char chars[5];

    ints[0] = 1;
    volatile int d = ints[0];

    shorts[4] = 8;
    volatile short e = shorts[4];

    chars[3] = 0x40;
    volatile char f = chars[3];

    return 0;
}
