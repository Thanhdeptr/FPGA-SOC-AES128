/*
 * source.c
 *
 *  Created on: May 5, 2025
 *      Author: phann
 */

#include "system.h"
#include "io.h"
#include <stdint.h>
#include <stdio.h>
#include <unistd.h> // usleep, neu duoc ho tro

void aes128_write_datain(uint32_t datain[4]) {
    int i;
    for (i = 0; i < 4; i++) {
        IOWR(ASE128_IP_0_BASE, i, datain[i]);
    }
}

void aes128_write_key(uint32_t key[4]) {
    int i;
    for (i = 0; i < 4; i++) {
        IOWR(ASE128_IP_0_BASE, 4 + i, key[i]);
    }
}

void aes128_start(void) {
    IOWR(ASE128_IP_0_BASE, 8, 1);
}

int aes128_done(void) {
    return (IORD(ASE128_IP_0_BASE, 9) & 0x1);
}

void aes128_read_output(uint32_t output[4]) {
    int i;
    for (i = 0; i < 4; i++) {
        output[i] = IORD(ASE128_IP_0_BASE, i);
    }
}

int main(void) {
    uint32_t plaintext[4] = {
        0xe0370734,
        0x313198a2,
        0x885a308d,
        0x3243f6a8
    };

    uint32_t cipherkey[4] = {
        0x09cf4f3c,
        0xabf71588,
        0x28aed2a6,
        0x2b7e1516
    };

    uint32_t ciphertext[4];
    int wait_count;
    int i;

    printf("=== BAT DAU MA HOA AES128 ===\n");

    // Buoc 1: Ghi du lieu dau vao
    printf("1. Ghi plaintext...\n");
    aes128_write_datain(plaintext);

    // Buoc 2: Ghi khoa AES
    printf("2. Ghi khoa AES...\n");
    aes128_write_key(cipherkey);

    // Buoc 3: Gui tin hieu bat dau
    printf("3. Gui tin hieu START...\n");
    aes128_start();

    // Buoc 4: Cho AES ma hoa xong
    printf("4. Cho AES hoan thanh...\n");
    wait_count = 0;
    while (!aes128_done()) {
        usleep(10); // co the bo neu khong co timer
        wait_count++;
    }

    printf("Hoan thanh! So vong cho: %d\n", wait_count);

    // Buoc 5: Doc ket qua
    aes128_read_output(ciphertext);

    // In ket qua
    printf("=== KET QUA MA HOA ===\n");
    printf("Ciphertext (MSB -> LSB):\n");
    for (i = 3; i >= 0; i--) {
        printf("%08X ", (unsigned int)ciphertext[i]);
    }
    printf("\n");

    while (1); // Giu chuong trinh chay

    return 0;
}




