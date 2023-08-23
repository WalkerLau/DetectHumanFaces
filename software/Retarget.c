#include <stdio.h>
#include "CM3DS_MPS2.h"

//#pragma import(__use_no_semihosting_swi)


extern int  sendchar(int ch);  /* in Serial.c */
extern int  getkey(void);      /* in Serial.c */
extern long timeval;           /* in Time.c   */


struct __FILE { int handle; /* Add whatever you need here */ };
FILE __stdout;
FILE __stdin;


int fputc(int ch, FILE *f) {
  if(ch == '\n') uart_SendChar(UART,'\r');
  uart_SendChar(UART,ch);
  return (ch);
}

int fgetc(FILE *f) {
  char buf;
  buf = uart_ReceiveChar(UART);
  uart_SendChar(UART,buf);
  if(buf == '\r') buf = '\n';
  return (buf);
}


int ferror(FILE *f) {
  /* Your implementation of ferror */
  return EOF;
}


void _ttywrch(int ch) {
  uart_SendChar(UART,ch);
}


void _sys_exit(int return_code) {
  while (1);    /* endless loop */
}
