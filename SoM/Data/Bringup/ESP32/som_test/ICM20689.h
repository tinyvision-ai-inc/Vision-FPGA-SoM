#ifndef __ICM20689_H__
#define __ICM20689_H__

#include "Arduino.h"
#include <Wire.h>



#define ICM20689_SELF_TEST_X_GYRO    (0x00)
#define ICM20689_SELF_TEST_Y_GYRO    (0x01)
#define ICM20689_SELF_TEST_Z_GYRO    (0x02)
#define ICM20689_SELF_TEST_X_ACCEL   (0x0D)
#define ICM20689_SELF_TEST_Y_ACCEL   (0x0E)
#define ICM20689_SELF_TEST_Z_ACCEL   (0x0F)

#define ICM20689_XG_OFFS_USRH        (0x13)
#define ICM20689_XG_OFFS_USRL        (0x14)
#define ICM20689_YG_OFFS_USRH        (0x15)
#define ICM20689_YG_OFFS_USRL        (0x16)
#define ICM20689_ZG_OFFS_USRH        (0x17)
#define ICM20689_ZG_OFFS_USRL        (0x18)

#define ICM20689_SMPLRT_DIV          (0x19)

#define ICM20689_CONFIG              (0x1A)
#define ICM20689_GYRO_CONFIG         (0x1B)
#define ICM20689_ACCEL_CONFIG        (0x1C)
#define ICM20689_ACCEL_CONFIG_2      (0x1D)
#define ICM20689_LP_MODE_CFG         (0x1E)

#define ICM20689_FIFO_EN             (0x23)

#define ICM20689_FSYNC_INT           (0x36)

#define ICM20689_INT_PIN_CFG         (0x37)

#define ICM20689_INT_ENABLE          (0x38)

#define ICM20689_INT_STATUS          (0x3A)

#define ICM20689_ACCEL_XOUT_H        (0x3B)
#define ICM20689_ACCEL_XOUT_L        (0x3C)
#define ICM20689_ACCEL_YOUT_H        (0x3D)
#define ICM20689_ACCEL_YOUT_L        (0x3E)
#define ICM20689_ACCEL_ZOUT_H        (0x3F)
#define ICM20689_ACCEL_ZOUT_L        (0x40)

#define ICM20689_TEMP_OUT_H          (0x41)
#define ICM20689_TEMP_OUT_L          (0x42)

#define ICM20689_GYRO_XOUT_H         (0x43)
#define ICM20689_GYRO_XOUT_L         (0x44)
#define ICM20689_GYRO_YOUT_H         (0x45)
#define ICM20689_GYRO_YOUT_L         (0x46)
#define ICM20689_GYRO_ZOUT_H         (0x47)
#define ICM20689_GYRO_ZOUT_L         (0x48)
 
#define ICM20689_SIGNAL_PATH_RESET   (0x68)
 
#define ICM20689_ACCEL_INTEL_CTRL    (0x69)

#define ICM20689_USER_CTRL           (0x6A)

#define ICM20689_PWR_MGMT_1          (0x6B)
#define ICM20689_PWR_MGMT_2          (0x6C)

#define ICM20689_FIFO_COUNTH         (0x72)
#define ICM20689_FIFO_COUNTL         (0x73)
#define ICM20689_FIFO_R_W            (0x74)

#define ICM20689_WHO_AM_I            (0x75)

#define ICM20689_XA_OFFSET_H         (0x77)
#define ICM20689_XA_OFFSET_L         (0x78)
#define ICM20689_YA_OFFSET_H         (0x79)
#define ICM20689_YA_OFFSET_L         (0x7A)
#define ICM20689_ZA_OFFSET_H         (0x7D)
#define ICM20689_ZA_OFFSET_L         (0x7E)

#define ICM20689_ID		0x98

#define ICM20689_I2C_ADDRESS 0x69

class ICM20689
{
public:
	ICM20689();

	void begin(uint8_t addr=ICM20689_I2C_ADDRESS);
	void reset();
	uint8_t init();
	void getGyro(int16_t* gyro);
	void getAccel(int16_t* accel);
	int16_t getTemp(void);

private:
	uint8_t i2c_address;

	int8_t read8(uint8_t addr);
	void readMultiple(uint8_t addr, uint8_t len, uint8_t* ret);

	void write8(uint8_t addr, uint8_t data);
};

#endif
