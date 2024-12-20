#include <esp_now.h>
#include <Wire.h>
#include <WiFi.h>
#include <Arduino_LSM6DSOX.h>
#include "Adafruit_MLX90393.h"


Adafruit_MLX90393 sensor = Adafruit_MLX90393();
#define MLX90393_CS 10
//#define MLX90393_DEFAULT_ADDR (0x18)


//timer for transmission freq
unsigned long timer = 0;

//digital pin for flow meter - SET THIS!
//const int inputPin = 35; // GPIO 35 in this case

//touchread
int touchSens = 0;

// REPLACE WITH THE RECEIVER'S MAC Address
uint8_t broadcastAddress[] = {0x94, 0xB9, 0x7E, 0xD2, 0x14, 0x1C};

// Structure example to send data
// Must match the receiver structure
typedef struct struct_message {
    int id; // must be unique for each sender board
    //magnetometer
    float val1; 
    float val2;
    float val3;     
    //Bangle
    float val4; 
    float val5; 
    float val6; 
    //accelerometer
    float val7;
    float val8;
    float val9;
    //digitalread flow meter
    int val10;
    //analogread (press sensor or water sensor)
    int val11;
    //touchsensor
    float val12;
  
   
} struct_message;

// Create a struct_message called myData
struct_message myData;

// Create peer interface
esp_now_peer_info_t peerInfo;

// callback when data is sent
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("\r\Status:\t");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Success" : "Fail");
}

 
void setup() {
  // Init Serial Monitor
  Serial.begin(115200);

  // Digital Read
 // pinMode(inputPin, INPUT_PULLDOWN);

  analogReadResolution(12);

 if (!IMU.begin()) {
    Serial.println("Failed to initialize IMU!");

    while (1);
  }

 delay(1000);


  if (! sensor.begin_I2C()) {          // hardware I2C mode, can pass in address & alt Wire
  //if (! sensor.begin_SPI(MLX90393_CS)) {  // hardware SPI mode
    Serial.println("No sensor found ... check your wiring?");
    while (1) { delay(10); }
  }
  Serial.println("Found a MLX90393 sensor");


//Set magnetometer gain
sensor.setGain(MLX90393_GAIN_1X);
  
// Set resolution, per axis
sensor.setResolution(MLX90393_X, MLX90393_RES_17);
sensor.setResolution(MLX90393_Y, MLX90393_RES_17);
sensor.setResolution(MLX90393_Z, MLX90393_RES_16);


// Set oversampling
sensor.setOversampling(MLX90393_OSR_3);

// Set digital filtering
sensor.setFilter(MLX90393_FILTER_5);

// Set device as a Wi-Fi Station
WiFi.mode(WIFI_STA);

// Init ESP-NOW
if (esp_now_init() != ESP_OK) {
  Serial.println("Error initializing ESP-NOW");
  return;
   }

  // Once ESPNow is successfully Init, we will register for Send CB to
  // get the status of Trasnmitted packet
  //esp_now_register_send_cb(OnDataSent);
  
  // Register peer
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;  
  peerInfo.encrypt = false;
  
  // Add peer        
  if (esp_now_add_peer(&peerInfo) != ESP_OK){
    Serial.println("Failed to add peer");
    return;
  }
}
 
void loop() {

  //Gyro-acc variables
 float x, y, z, x1, y1, z1;

 //int pinState = digitalRead(inputPin);

 //Get MXL event, normalized to uTesla */
  sensors_event_t event;
  // orientationData, linearAccelData;
  sensor.getEvent(&event); 

  if((millis()-timer)>10)
  
  {

  if (IMU.gyroscopeAvailable()) {
    IMU.readGyroscope(x, y, z);
    }

  if (IMU.accelerationAvailable()) {
    IMU.readAcceleration(x1, y1, z1);
    }



  // Set values to send
  myData.id = 6; //Set ID board number
  myData.val1 = event.magnetic.x;
  myData.val2 = event.magnetic.y;
  myData.val3 = event.magnetic.z;
  myData.val4 = x;
  myData.val5 = y;
  myData.val6 = z;
  myData.val7 = x1;
  myData.val8 = y1;
  myData.val9 = z1;
  myData.val10 = 0;
  myData.val11 = analogRead(17);
  myData.val12 = 0;
  


  
 
  // Send message via ESP-NOW
  esp_err_t result = esp_now_send(broadcastAddress, (uint8_t *) &myData, sizeof(myData));
  if (result == ESP_OK) {
    Serial.println("Delivered");
    
  }
  else {
    Serial.println("Error sending the data");
  }
  timer = millis();
  }
}
