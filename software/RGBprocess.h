#ifndef RGBPROCESS_H
#define RGBPROCESS_H

#include <stdint.h>

#define ROWS        480
#define COLS        640   
#define RGBsize     ROWS*COLS
#define MIN(a,b)  ((a) > (b) ? (b) : (a))

void rgb2gray(uint16_t* img, uint8_t* gray);

#endif