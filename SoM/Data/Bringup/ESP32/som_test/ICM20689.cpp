#include "ICM20689.h"

ICM20689::ICM20689(){}

void ICM20689::begin(uint8_t addr) {
	Wire.begin();
	i2c_address = addr;
}

void ICM20689::reset(void) {
	write8(ICM20689_PWR_MGMT_1, 0b10000000); // Reset the part
	delay(10);
	write8(ICM20689_PWR_MGMT_1, 0b00000000); // Wakeup
	delay(10);
	write8(ICM20689_PWR_MGMT_1, 0b00000001); // Auto select the best clock source
	delay(10);
}

int16_t ICM20689::getTemp(void) {
	uint8_t data[2];
	int16_t ret;
	readMultiple(ICM20689_TEMP_OUT_H, 2, data);
	ret = (int16_t)( (data[0]<<8) | data[1]);
	return ret;
}

void ICM20689::getGyro(int16_t* ret) {
	uint8_t data[6];
	readMultiple(ICM20689_GYRO_XOUT_H, 6, data);
	ret[0] = (int16_t)( (data[0]<<8) | data[1]);
	ret[1] = (int16_t)( (data[2]<<8) | data[3]);
	ret[2] = (int16_t)( (data[4]<<8) | data[5]);
}

void ICM20689::getAccel(int16_t* ret) {
	uint8_t data[6];
	readMultiple(ICM20689_ACCEL_XOUT_H, 6, data);
	ret[0] = (int16_t)( (data[0]<<8) | data[1]);
	ret[1] = (int16_t)( (data[2]<<8) | data[3]);
	ret[2] = (int16_t)( (data[4]<<8) | data[5]);
}

uint8_t ICM20689::init(void) {
	delay(100); // Wait for things to settle, max of 100ms
	reset();

	// Check for the ID:
	uint8_t id = read8(ICM20689_WHO_AM_I);
	if (id != ICM20689_ID)
		return 1;

	// Read out the self test registers
	uint8_t self_test[6];
	for (uint8_t i=0; i<6; i++) {
		self_test[i] = read8(i);
		Serial.println(self_test[i], HEX);
	}
	Serial.println();

	write8(ICM20689_CONFIG, 0x03); // DLPF_CFG = 3, gyro filter = 41/59.0, gyro rate = 1KHz, temp filter = 42
	delay(10);
/*	
	uint8_t gyro_cfg = 0;
	gyro_cfg = (gyro_cfg & 0xE7) | (_gyro_range << 3);
	WriteRegister(REG_GYRO_CONFIG, gyro_cfg); // gyro full scale = ±2000dps, FCHOICE_B = 00
	HAL_Delay(10);
	
	// Configuring accelerometer
	
	uint8_t accel_cfg = 0;
	accel_cfg = (accel_cfg & 0xE7) | (_accel_range << 3);
	WriteRegister(REG_ACCEL_CONFIG, accel_cfg); // accel full scale = ±16g
	HAL_Delay(10);
	
	WriteRegister(REG_ACCEL_CONFIG2, 0x03); // ACCEL_FCHOICE_B = 0, A_DLPF_CFG = 3 filter=44.8/61.5 rate=1KHz
	HAL_Delay(10);
	
	// Sample rate divider (effective only if FCHOICE_B is 0b00 and 0 < DLPF_CFG < 7)
	
	WriteRegister(REG_SMPLRT_DIV, 0); // SAMPLE_RATE = INTERNAL_SAMPLE_RATE / (1 + SMPLRT_DIV) Where INTERNAL_SAMPLE_RATE = 1kHz
	HAL_Delay(10);
	
	// Enable interrupt
	
	// The logic level for INT/DRDY pin is active high.
	// INT/DRDY pin is configured as push-pull.
	// INT/DRDY pin indicates interrupt pulse’s width is 50us.
	// Interrupt status is cleared only by reading INT_STATUS register
	WriteRegister(REG_INT_PIN_CFG, 0x00);
	HAL_Delay(10);
	
	WriteRegister(REG_INT_ENABLE, 0x01); // Data ready interrupt enable
	HAL_Delay(10);
		write8(ICM20689_CONFIG, 0x3
*/
	return 0;
}

/**********************************************************************
* 			INTERNAL I2C FUNCTIONS			      *
**********************************************************************/
// writes a 8-bit word (d) to register pointer (a)
// when selecting a register pointer to read from, (d) = 0
void ICM20689::write8(uint8_t a, uint8_t d) {
  Wire.beginTransmission(i2c_address); // start transmission to device

  Wire.write(a); // sends register address to read from
  Wire.write(uint8_t(d)); // Write the data

  Wire.endTransmission(); // end transmission
  delay(1);
}


int8_t ICM20689::read8(uint8_t a) {
  uint8_t ret;

  Wire.beginTransmission((uint8_t)i2c_address); // start transmission to device

  // move the pointer to reg. of interest
  Wire.write(a);
  Wire.endTransmission(); // end transmission

  //Wire.beginTransmission((uint8_t)i2c_address); // start transmission to device
  Wire.requestFrom((uint8_t)i2c_address, 1);	// request 1 data byte

  ret = Wire.read(); // rx byte

  return ret;
}

void ICM20689::readMultiple(uint8_t addr, uint8_t len, uint8_t* ret) {

  Wire.beginTransmission((uint8_t)i2c_address); // start transmission to device

  // move the pointer to reg. of interest
  Wire.write(addr);
  Wire.endTransmission(); // end transmission

  //Wire.beginTransmission((uint8_t)i2c_address); // start transmission to device
  Wire.requestFrom((uint8_t)i2c_address, len);	// request 1 data byte
  for (uint8_t i=0; i<len; i++)
  	ret[i] = Wire.read(); // rx byte
	
}
