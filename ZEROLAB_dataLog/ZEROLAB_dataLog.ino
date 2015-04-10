#include <SD.h>
#include <SPI.h>
#include <Wire.h>

// how many milliseconds between grabbing data and logging it. 1000 ms is once a second
#define LOG_INTERVAL  10 // mills between entries (reduce to take more/faster data)

// how many milliseconds before writing the logged data permanently to disk
// set it to the LOG_INTERVAL to write each time (safest)
// set it to 10*LOG_INTERVAL to write all data every 10 datareads, you could lose up to 
// the last 10 reads if power is lost but it uses less power and is much faster!
#define SYNC_INTERVAL 1000 // mills between calls to flush() - to write data to the card
uint32_t syncTime = 0; // time of last sync()

#define ECHO_TO_SERIAL   0 // echo data to serial port
#define WAIT_TO_START    1  // Wait for serial input in setup()//WAIT FOR SWITCH

// the digital pins that connect to the LEDs
#define syncLED 2 //active LOW
#define greenLEDpin 3
#define redLEDpin 4
#define recordButtonLED 5
#define recordButton 6 //active LOW

// The analog pins that connect to the sensors
int zAxis = A0;
int yAxis = A1;
int xAxis = A2;
int zVal = 0;
int yVal = 0;
int xVal = 0;
#define aref_voltage 3.3         // we tie 3.3V to ARef and measure it with a multimeter!
#define bandgap_voltage 1.1      // this is not super guaranteed but its not -too- off
#define BANDGAPREF 14            // special indicator that we want to measure the bandgap

// for the data logging shield, we use digital pin 10 for the SD cs line
const int chipSelect = 10;

// the logging file
File logfile;

void error(char *str)
{
  Serial.print("error: ");
  Serial.println(str);
  while(1);
  // red LED indicates error
  digitalWrite(redLEDpin, HIGH);
}

void setup(void)
{
  Serial.begin(9600);
  Serial.println();
  
  // use debugging LEDs
  pinMode(syncLED, OUTPUT);
  pinMode(redLEDpin, OUTPUT);
  pinMode(greenLEDpin, OUTPUT);
  pinMode(recordButtonLED, OUTPUT);
  pinMode(recordButton, INPUT);
  
  digitalWrite(syncLED, HIGH);
  
#if WAIT_TO_START
  //Serial.println("Type any character to start");
  //while (!Serial.available());
  while(digitalRead(recordButton)==1);
#endif //WAIT_TO_START

  // initialize the SD card
  Serial.print("Initializing SD card...");
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(10, OUTPUT);
  
  // see if the card is present and can be initialized:
  if (!SD.begin(10, 11, 12, 13)) {
    error("Card failed, or not present");
  }
  Serial.println("card initialized.");
  
  // create a new file
  char filename[] = "LOGGER00.CSV";
  for (uint8_t i = 0; i < 100; i++) {
    filename[6] = i/10 + '0';
    filename[7] = i%10 + '0';
    if (! SD.exists(filename)) {
      // only open a new file if it doesn't exist
      logfile = SD.open(filename, FILE_WRITE); 
      break;  // leave the loop!
    }
  }
  
  if (! logfile) {
    error("couldnt create file");
  }
  
  Serial.print("Logging to: ");
  Serial.println(filename);

  logfile.println("millis,xVal,yVal,zVal,vcc");    
#if ECHO_TO_SERIAL
  Serial.println("millis,xVal,yVal,zVal,vcc");
#endif //ECHO_TO_SERIAL
 
  // If you want to set the aref to something other than 5v
  analogReference(EXTERNAL);
}

void loop(void)
{
  // delay for the amount of time we want between readings
  delay((LOG_INTERVAL -1) - (millis() % LOG_INTERVAL));
  
  digitalWrite(greenLEDpin, HIGH);
  if(digitalRead(recordButton)==0) {
    digitalWrite(recordButtonLED, HIGH);
  } else {
    digitalWrite(recordButtonLED, LOW);
  }
  
  // log milliseconds since starting
  uint32_t m = millis();
  logfile.print(m);           // milliseconds since start   
#if ECHO_TO_SERIAL
  Serial.print(m);         // milliseconds since start 
#endif

  zVal = analogRead(zAxis);
  yVal = analogRead(yAxis);
  xVal = analogRead(xAxis);
  
  logfile.print(", "); 
  logfile.print(xVal);
  logfile.print(", ");
  logfile.print(yVal);
  logfile.print(", ");
  logfile.print(zVal);
#if ECHO_TO_SERIAL
  Serial.print(", ");
  Serial.print(xVal);
  Serial.print(", ");
  Serial.print(yVal);
  Serial.print(", ");
  Serial.print(zVal);
#endif //ECHO_TO_SERIAL

  // Log the estimated 'VCC' voltage by measuring the internal 1.1v ref
  analogRead(BANDGAPREF); 
  delay(10);
  int refReading = analogRead(BANDGAPREF); 
  float supplyvoltage = (bandgap_voltage * 1024) / refReading; 
  
  logfile.print(", ");
  logfile.print(supplyvoltage);
#if ECHO_TO_SERIAL
  Serial.print(", ");   
  Serial.print(supplyvoltage);
#endif // ECHO_TO_SERIAL

  logfile.println();
#if ECHO_TO_SERIAL
  Serial.println();
#endif // ECHO_TO_SERIAL

  digitalWrite(greenLEDpin, LOW);
  digitalWrite(recordButtonLED, LOW);
  // Now we write data to disk! Don't sync too often - requires 2048 bytes of I/O to SD card
  // which uses a bunch of power and takes time
  if ((millis() - syncTime) < SYNC_INTERVAL) return;
  syncTime = millis();
  
  // blink LED to show we are syncing data to the card & updating FAT!
  if(digitalRead(recordButton)==0) {
  #if ECHO_TO_SERIAL
    Serial.println("writing...");
  #endif // ECHO_TO_SERIAL
    digitalWrite(syncLED, LOW);
    digitalWrite(redLEDpin, HIGH);
    logfile.flush();
    digitalWrite(redLEDpin, LOW);
  } else {
    digitalWrite(syncLED, HIGH);
  }
}


