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


#include "cmos_sensor_output_generator/cmos_sensor_output_generator.h"
#include "cmos_sensor_output_generator/cmos_sensor_output_generator_regs.h"
#include "cmos_sensor_output_generator/cmos_sensor_output_generator.c"

#define CMOS_SENSOR_OUTPUT_GENERATOR_0_BASE       (0x10000840) /* cmos_sensor_output_generator base address from system.h (ADAPT TO YOUR DESIGN) */
#define CMOS_SENSOR_OUTPUT_GENERATOR_0_PIX_DEPTH  (12)     /* cmos_sensor_output_generator pix depth from system.h (ADAPT TO YOUR DESIGN) */
#define CMOS_SENSOR_OUTPUT_GENERATOR_0_MAX_WIDTH  (640)    /* cmos_sensor_output_generator max width from system.h (ADAPT TO YOUR DESIGN) */
#define CMOS_SENSOR_OUTPUT_GENERATOR_0_MAX_HEIGHT (480)    /* cmos_sensor_output_generator max height from system.h (ADAPT TO YOUR DESIGN) */
//#define HPS_0_BRIDGES_BASE (0x0000)            /* address_span_expander base address from system.h (ADAPT TO YOUR DESIGN) */
//#define HPS_0_BRIDGES_SPAN (268435456) /* address_span_expander span from system.h (ADAPT TO YOUR DESIGN) */
//#define ONE_MB (1024 * 1024)
#define CAMERA_CONTROLLER_0_BASE 0x10000820

int main()
{
	uint32_t addr3 = HPS_0_BRIDGES_BASE + 4;
	uint32_t readdata = IORD_32DIRECT(addr3, 0);


	printf("we read %04x before from memory", readdata);
	cmos_sensor_output_generator_dev cmos_sensor_output_generator = cmos_sensor_output_generator_inst(CMOS_SENSOR_OUTPUT_GENERATOR_0_BASE,
	                                                                                                      CMOS_SENSOR_OUTPUT_GENERATOR_0_PIX_DEPTH,
	                                                                                                      CMOS_SENSOR_OUTPUT_GENERATOR_0_MAX_WIDTH,
	                                                                                                     CMOS_SENSOR_OUTPUT_GENERATOR_0_MAX_HEIGHT);
	cmos_sensor_output_generator_init(&cmos_sensor_output_generator);

	cmos_sensor_output_generator_stop(&cmos_sensor_output_generator);

	cmos_sensor_output_generator_configure(&cmos_sensor_output_generator,
										   640,
										   480,
										   CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_FRAME_FRAME_BLANK_MIN,
										   CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_FRAME_LINE_BLANK_MIN,
										   CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_LINE_LINE_BLANK_MIN,
										   CMOS_SENSOR_OUTPUT_GENERATOR_CONFIG_LINE_FRAME_BLANK_MIN);

	cmos_sensor_output_generator_start(&cmos_sensor_output_generator);

	uint32_t addr = CAMERA_CONTROLLER_0_BASE;
	uint32_t writedata = 1;
	IOWR_32DIRECT(addr, 8, writedata);
	uint32_t status = 0;
	int flag=0;
	while(flag!=1){
		status = IORD_32DIRECT(addr, 8);
		flag = status & (0x0008);
		printf("STATUS REGISTER is %04x", status);
	}



	uint32_t addr2 = HPS_0_BRIDGES_BASE + 4;
	uint32_t readdata2 = IORD_32DIRECT(addr2, 0);
	printf("we read %04x after from memory", readdata2);

  return 0;
}
