/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include "io.h"
#include "system.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <inttypes.h>
#include <stdio.h>
#include <i2c_io.h>
#include <i2c_regs.h>
#include <i2c.c>
#include <i2c.h>


#define HPS_0_BRIDGES_BASE (0x0000)            /* address_span_expander base address from system.h (ADAPT TO YOUR DESIGN) */
#define HPS_0_BRIDGES_SPAN (268435456) /* address_span_expander span from system.h (ADAPT TO YOUR DESIGN) */
#define ONE_MB (1024 * 1024)
#define CAMERA_CONTROLLER_0_BASE 0x10000820

#define I2C_FREQ              (50000000) /* Clock frequency driving the i2c core: 50 MHz in this example (ADAPT TO YOUR DESIGN) */
#define TRDB_D5M_I2C_ADDRESS  (0xba)

#define TRDB_D5M_0_I2C_0_BASE (0x10000808)   /* i2c base address from system.h (ADAPT TO YOUR DESIGN) I haven't defined this yet*/

bool trdb_d5m_write(i2c_dev *i2c, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

bool trdb_d5m_read(i2c_dev *i2c, uint8_t register_offset, uint16_t *data) {
    uint8_t byte_data[2] = {0, 0};

    int success = i2c_read_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        *data = ((uint16_t) byte_data[0] << 8) + byte_data[1];
        return true;
    }
}

void i2c_configs(void){
	// Writing 256 to register 30 for snapshot mode
	i2c_dev i2c = i2c_inst((void *) TRDB_D5M_0_I2C_0_BASE);
    i2c_init(&i2c, I2C_FREQ);

    bool success = true;
	success &= trdb_d5m_write(&i2c, 30 , 256); // snapshot mode

	/* The following configuarions should be set for 640*480 resolution with binning*/
    success &= trdb_d5m_write(&i2c, 34 , 51); // 51 is 0b110011
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 34, &readdata);

    /* write the 16-bit value 51 to register 35 */
    success &= trdb_d5m_write(&i2c, 35 , 51);
    readdata = 0;
    success &= trdb_d5m_read(&i2c, 35, &readdata);

    /* write the 16-bit value 2559 to register 4 */
    success &= trdb_d5m_write(&i2c, 4 , 2559);
    readdata = 0;
    success &= trdb_d5m_read(&i2c, 4, &readdata);

    /* write the 16-bit value 1919 to register 3 */
    success &= trdb_d5m_write(&i2c, 3 , 1919);
    readdata = 0;
    success &= trdb_d5m_read(&i2c, 3, &readdata);
}


int main()
{
	// First operations for turning on the camera
	uint32_t addr = CAMERA_CONTROLLER_0_BASE;
	uint32_t writedata = 0;
	IOWR_32DIRECT(addr, 12, writedata); // assert reset_n 3*4=12
	writedata = 1;
	IOWR_32DIRECT(addr, 12, writedata); // de-assert reset_n
	// I2C configurations
	i2c_configs();
	// configuring slave registers
	uint32_t StartAddress = 0;
	IOWR_32DIRECT(addr, 0, StartAddress); // we first define the starting address of the SDRAM
	uint32_t Length = 1200; // length : here we specify number of bursts required for one image
	IOWR_32DIRECT(addr, 4, Length); // Then define the length. 10 is just to test
	writedata = 1;
	IOWR_32DIRECT(addr, 8, writedata); // write to modulestatus(0) to turn on the modules

	// here we trigger the first frame capture
	writedata = 1;
	IOWR_32DIRECT(addr, 16, writedata); // address is base + 4*4 = 16
	// wait for 20ns
	// de-assert the trigger
	writedata = 0;
	IOWR_32DIRECT(addr, 16, writedata);

	uint32_t status = 0;
	uint32_t flag = 0;
	while(flag!=0x10){
		status = IORD_32DIRECT(addr, 8); //read modulestatus
		flag = status & (0x0010); // read modulestatus(4) and if it's 1, then we are done writing one frame
		// printf("***STATUS REGISTER is %04x*** \n", status);

	}
	// here we are done with wrting to the sd card
	printf("***STATUS REGISTER is %04x*** \n", status);
	// now we read from the sd card
	uint32_t addr2 = HPS_0_BRIDGES_BASE + 4;
	uint32_t readdata2 = IORD_32DIRECT(addr2, 0);
	// write a .ppm
	char* filename = "/mnt/host/image.ppm";
	FILE *foutput = fopen(filename, "w");
	if (!foutput) {
		printf("Error: could not open \"%s\" for writing\n", filename);
		return 0;
	}

	int width = 320;
	int height = 240;

	fprintf(foutput, "P3\n%d %d\n%d\n", width, height, 255); //defining header, width, height and max intensity

	uint16_t pix1, pix2; // with each read we get 2 pixels
	uint8_t r1, g1, b1, r2, g2, b2; //we put each red, green, blue information in 8 bit format by upscale
	uint32_t final_word_address = sizeof(uint32_t)*Length*32; //number of bursts*4 is where final pixel is located
	//int j = 0;
	for (uint32_t i = 0; i < final_word_address; i += sizeof(uint32_t)) {
		uint32_t addr = HPS_0_BRIDGES_BASE + i;
		// Read through address span expander
		uint32_t readdata = IORD_32DIRECT(addr, 0); // two pixels

		pix1 = (uint16_t)(readdata & 0x0000FFFF);
		pix2 = (uint16_t)((readdata & 0xFFFF0000) >> 16);
		// each pixel is 16 bits of 5 6 5 RGB format data
		r1 = (uint8_t)((pix1) >> 11) * 8; // because we should write 1 byte and red is only 5 bit => 256/32=8
		g1 = (uint8_t)((pix1 & 0x03F0) >> 5) * 4; // 256/64
		b1 = (uint8_t)((pix1 & 0x001F) * 8); //256/32

		r2 = (uint8_t)((pix2) >> 11) * 8; // because we should write 1 byte and red is only 5 bit => 256/32=8
		g2 = (uint8_t)((pix2 & 0x03F0) >> 5) * 4; // 256/64
		b2 = (uint8_t)((pix2 & 0x001F) * 8); //256/32
		fprintf(foutput, "%d\n%d\n%d\n%d\n%d\n%d\n",r1,g1,b1,r2,g2,b2);
	}
	fclose(foutput);

  return 0;
}
