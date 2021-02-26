/*
 * Tester for the Vision SoM breakout board
 */

#include <Wire.h>
#include "ICM20689.h"
ICM20689 imu;

#include <INA219.h>
INA219 monitor;

#define OFFSET_POWER 0
#define OFFSET_VOLTAGE 0

void setup()
{
  Serial.begin (115200);  
  delay(100); // Let things stabilize
  //Wire.begin (19, 18);   // sda= GPIO_21 /scl= GPIO_22
  Wire.begin(23, 22);

  imu.begin(ICM20689_I2C_ADDRESS);
  if(imu.init() == 0)
    Serial.println("Completed IMU config");
  else
    Serial.println("IMU Error!");
  
  //Scanner();
  /*
  monitor.begin();
  // setting up our configuration
  monitor.configure(INA219::RANGE_16V, INA219::GAIN_1_40MV, INA219::ADC_8SAMP, INA219::ADC_8SAMP, INA219::CONT_SH_BUS);
  // calibrate with our values
  monitor.calibrate(1.0, .1, 5, .2);
  monitor.recalibrate();
  */
  Serial.println(F("ax ay az gx gy gz t"));
}

void Scanner ()
{
  Serial.println ();
  Serial.println ("I2C scanner. Scanning ...");
  byte count = 0;

  Wire.begin();
  for (byte i = 8; i < 120; i++)
  {
    Wire.beginTransmission (i);          // Begin I2C transmission Address (i)
    if (Wire.endTransmission () == 0)  // Receive 0 = success (ACK response) 
    {
      Serial.print ("Found address: ");
      Serial.print (i, DEC);
      Serial.print (" (0x");
      Serial.print (i, HEX);     // PCF8574 7 bit address
      Serial.println (")");
      count++;
    }
  }
  Serial.print ("Found ");      
  Serial.print (count, DEC);        // numbers of devices
  Serial.println (" device(s).");
}

void getINA() {
  float shuntVoltage = 0;
  float busVoltage = 0;
  float current_mA = 0;
  float loadVoltage = 0;
  float power_mW = 0;
  for (int i=0; i<10; i++) {
    shuntVoltage += monitor.shuntVoltage() * 1000-OFFSET_VOLTAGE;
  }
  shuntVoltage /= 10.0;
  busVoltage = monitor.busVoltageRaw();
  current_mA = monitor.shuntCurrent() * 1000; //-OFFSET_CURRENT;
  
  power_mW = monitor.busPower() * 1000;
  loadVoltage = monitor.busVoltageRaw();
  //shuntVoltage += monitor.shuntVoltage() * 1000 - OFFSET_VOLTAGE;

  Serial.print("Bus Voltage:   "); Serial.print(busVoltage); Serial.println(" V");
  Serial.print("Shunt Voltage: "); Serial.print(shuntVoltage); Serial.println(" mV");
  Serial.print("Load Voltage:  "); Serial.print(loadVoltage); Serial.println(" V");
  Serial.print("Current:       "); Serial.print(current_mA); Serial.println(" mA");
  Serial.print("Power:         "); Serial.print(power_mW); Serial.println(" mW");
  Serial.println("");

 Serial.print(power_mW);
 //Serial.print(", ");
 //Serial.print(loadVoltage);
 //Serial.print(", ");
 //Serial.print(shuntVoltage);
 Serial.println();
}

int16_t accel[3];
int16_t gyro[3];
float temperature;

void loop()
{
  //getINA();
  delay(10);
  imu.getAccel(accel);
  imu.getGyro(gyro);
  for(uint8_t i =0 ; i<3; i++) {
    Serial.print(accel[i]);
    Serial.print(F(" "));
  }
  for(uint8_t i =0 ; i<3; i++) {
    Serial.print(gyro[i]);
    Serial.print(F(" "));
  }
  temperature = imu.getTemp()/256.0;
  Serial.print(temperature);

  Serial.println();
}
