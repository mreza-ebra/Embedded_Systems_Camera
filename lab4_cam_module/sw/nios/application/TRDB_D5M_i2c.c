#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "i2c/i2c.h"

#define I2C_FREQ              (50000000) /* Clock frequency driving the i2c core: 50 MHz in this example (ADAPT TO YOUR DESIGN) */
#define TRDB_D5M_I2C_ADDRESS  (0xba)

#define TRDB_D5M_0_I2C_0_BASE (0x0000)   /* i2c base address from system.h (ADAPT TO YOUR DESIGN) */

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

int main(void) {
    i2c_dev i2c = i2c_inst((void *) TRDB_D5M_0_I2C_0_BASE);
    i2c_init(&i2c, I2C_FREQ);

    bool success = true;

    /* The following configuarions should be set for 640*480 resolution with binning*/
    /* write the 16-bit value 51 to register 34 */
    success &= trdb_d5m_write(&i2c, 34 , 51); // 51 is 0b110011
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 34, &readdata);

    /* write the 16-bit value 51 to register 35 */
    success &= trdb_d5m_write(&i2c, 35 , 51);
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 35, &readdata);
    
    /* write the 16-bit value 2559 to register 4 */
    success &= trdb_d5m_write(&i2c, 4 , 2559);
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 4, &readdata); 
    
    /* write the 16-bit value 1919 to register 3 */
    success &= trdb_d5m_write(&i2c, 3 , 1919);
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 3, &readdata);
    
    /* for reset, uncomment following lines */
    /*success &= trdb_d5m_write(&i2c, 3 , 1919);
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 34, &readdata);*/

    if (success) {
        return EXIT_SUCCESS;
    } else {
        return EXIT_FAILURE;
    }
}
