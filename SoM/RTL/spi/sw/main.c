#include <stdio.h>
#include "spi_lib.h"

#define SPI_NOP 0x00
#define SPI_INIT 0x01
#define SPI_SEND_BIT_INV 0x02
#define SPI_READ_REQ_BIT_INV 0x03
#define SPI_SET_LED 0x04
#define SPI_READ_REQ_LED 0x05
#define SPI_SEND_VEC 0x06
#define SPI_READ_VEC 0x07

int main()
{
   spi_init();

   uint8_t status, id;

   spi_get_id_status(&id, &status);
   printf("Got ID: 0x%x, Status: 0x%x", id, status);

   return 0;
}
