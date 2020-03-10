/*
 * Vision SoM Artemis Nano adapter
 * Refer to the drawings at: https://cdn.sparkfun.com/assets/5/5/1/6/3/RedBoard-Artemis-Nano.pdf
 */

// SPI clock is a max of 23MHz when talking to flash and TBD when talking to the FPGA
#define SPI_FREQUENCY 5e6


// SoM control signals
#define SOM_POWER       1
#define SOM_FLASH_SEL   5
#define SOM_PROG_FLASH  3
#define SOM_RESET_N     15
#define SOM_DONE        8

#define SOM_PIX_RESET_N 15
#define SOM_SCK         11
#define SOM_MISO        13
#define SOM_MOSI        12
#define SOM_SSN         4
#define SOM_IRQ         0
#define SOM_GPIO_0      14
#define SOM_GPIO_1      10
#define SOM_GPIO_2      9


// SoM voltages
#define SOM_VDD12        2
#define SOM_VDD18        16

#define LED LED_BUILTIN //Status LED on Artemis carrier boards

#include <Wire.h>

#include <INA219.h>
INA219 monitor;

#include "SPI.h"

#include <pixart.h>
#include <registers.h>
#include <tinyVisionFPGA.h>

#include "test_spi.h"

float vcc;

void setup()
{
  Serial.begin (230400);  
  delay(100);
  Serial.print("tinyVision.ai Inc. Artemis system\n");
  pinMode(LED, OUTPUT);

  analogReadResolution(14); //Set resolution to 14 bit

  //boardBugFix();
  Serial.print("Internal Vcc: ");
  Serial.print(getIntVcc());
  Serial.println("V");

  Serial.print("Internal Temp: ");
  Serial.print(getTemp());
  Serial.println("C");

  powerUp();
  Serial.print("1.2V Vcc: ");
  Serial.print(getCoreVcc());
  Serial.println("V");

  Serial.print("1.8V Vcc: ");
  Serial.print(getIOVcc());
  Serial.println("V");

  TwoWire myWire(3); //Will use pads 42/43
  Wire = myWire;
  Wire.begin();
  Scanner();

  //powerDown();

  monitor.begin();
  // setting up our configuration
  monitor.configure(INA219::RANGE_16V, INA219::GAIN_1_40MV, INA219::ADC_4SAMP, INA219::ADC_4SAMP, INA219::CONT_SH_BUS);
  // calibrate with our values
  monitor.calibrate(1.2, .1, 5, .2);
  monitor.recalibrate();
  Serial.print("Current: ");
  getINA();
  Serial.println("mA");


  // SPI0 is used here, mapped to SPI by the Arduino wrappers
  SPI.begin();

  //test_spi fpga;
  //fpga.testSPI(SPI);

  tvFPGA fpga(SPI_FREQUENCY, SOM_SSN, SOM_IRQ, SOM_RESET_N, SOM_DONE, SOM_FLASH_SEL, SOM_PROG_FLASH);
  digitalWrite(LED, HIGH);

  fpga.reset_fpga();
  fpga.wait_done();
  fpga.init_fpga();

  fpga.read_flash_jedec_id();

}




float getIntVcc(void) {
  int div3 = analogRead(ADC_INTERNAL_VCC_DIV3); //Read VCC across a 1/3 resistor divider
  return (float)div3 * 6 / 16384.0; //Convert 1/3 VCC to VCC
}

float getTemp(void) {
  int volts = analogRead(ADC_INTERNAL_TEMP);
  double internalTemp = volts * 3.3/16384.0; // Assume 3.3V voltage, fix this later
  return (internalTemp/0.0038); //Convert voltage to temp
}

float getCoreVcc(void) {
  int volts = analogRead(SOM_VDD12);
  return (float)volts *2 / 16384.0;
}

float getIOVcc(void) {
  int volts = analogRead(SOM_VDD18);
  return (float)volts *2 / 16384.0;
}

void powerUp(void) {
  pinMode(SOM_POWER, OUTPUT);
  digitalWrite(SOM_POWER, LOW);
  delay(100); // Allow power to settle
}

void powerDown(void) {
  pinMode(SOM_POWER, OUTPUT);
  digitalWrite(SOM_POWER, HIGH);
}

void Scanner ()
{
  Serial.println ();
  Serial.println ("I2C scanner. Scanning ...");
  byte count = 0;

  //wire.begin();
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
  float busvoltage = 0;
  float current_mA = 0;
  float loadvoltage = 0;
  float power_mW = 0;
  /*for (int i=0; i<10; i++) {
    shuntvoltage += monitor.shuntVoltage() * 1000-OFFSET_VOLTAGE;
  }
  shuntvoltage /= 10;
  busvoltage = monitor.busVoltageRaw();
  current_mA = monitor.shuntCurrent() * 1000-OFFSET_CURRENT;
  */
  power_mW = monitor.busPower() * 1000;
  //loadvoltage = monitor.busVoltageRaw();
  //shuntVoltage += monitor.shuntVoltage() * 1000 - OFFSET_VOLTAGE;
/*
  Serial.print("Bus Voltage:   "); Serial.print(busvoltage); Serial.println(" V");
  Serial.print("Shunt Voltage: "); Serial.print(shuntvoltage); Serial.println(" mV");
  Serial.print("Load Voltage:  "); Serial.print(loadvoltage); Serial.println(" V");
  Serial.print("Current:       "); Serial.print(current_mA); Serial.println(" mA");
  Serial.print("Power:         "); Serial.print(power_mW); Serial.println(" mW");
  Serial.println("");
 */
 Serial.println(power_mW);
 //Serial.println(shuntVoltage);
}

void loop()
{
  getINA();
  /*digitalWrite(LED, LOW);
  delay(100);
  digitalWrite(LED, HIGH);
  delay(100);
  */
}
