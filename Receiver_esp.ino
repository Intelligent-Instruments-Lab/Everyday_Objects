
#include <esp_now.h>
#include <WiFi.h>
#include <esp_wifi.h>

// Set your new MAC Address
uint8_t newMACAddress[] = {0x94, 0xB9, 0x7E, 0xD2, 0x14, 0x1C};


// Structure example to receive data
// Must match the sender structure
typedef struct struct_message {
    int id; // must be unique for each sender board 
    float val1;
    float val2;  
    float val3; 
    float val4; 
    float val5; 
    float val6;
    float val7;
    float val8;
    float val9;
    int val10;
    int val11;
    int val12; 
   
}struct_message;

// Create a struct_message called myData
struct_message myData;

// Create a structure to hold the readings from each board (now we have two)
struct_message board1;
struct_message board2;
struct_message board3;
struct_message board4;
struct_message board5;
struct_message board6;

// Create an array with all the structures (now we have two)
struct_message boardsStruct[6] = {board1, board2, board3, board4, board5, board6};

// callback function that will be executed when data is received
void OnDataRecv(const uint8_t * mac_addr, const uint8_t *incomingData, int len) {
  
  //Get peer MAC address
  char macStr[18];
  //Serial.print("Packet received from: ");
  //snprintf(macStr, sizeof(macStr), "%02x:%02x:%02x:%02x:%02x:%02x",
  //         mac_addr[0], mac_addr[1], mac_addr[2], mac_addr[3], mac_addr[4], mac_addr[5]);
  //Serial.println(macStr);

  //Copy content incomingData into myData variable
  memcpy(&myData, incomingData, sizeof(myData));

  
  // Update the structures with the new incoming data
  boardsStruct[myData.id-1].id = myData.id;
  boardsStruct[myData.id-1].val1 = myData.val1;
  boardsStruct[myData.id-1].val2 = myData.val2;
  boardsStruct[myData.id-1].val3 = myData.val3;
  boardsStruct[myData.id-1].val4 = myData.val4;
  boardsStruct[myData.id-1].val5 = myData.val5;
  boardsStruct[myData.id-1].val6 = myData.val6;
  boardsStruct[myData.id-1].val7 = myData.val7;
  boardsStruct[myData.id-1].val8 = myData.val8;
  boardsStruct[myData.id-1].val9 = myData.val9;
  boardsStruct[myData.id-1].val10 = myData.val10;
  boardsStruct[myData.id-1].val11 = myData.val11;
  boardsStruct[myData.id-1].val12 = myData.val12;
  
  
  Serial.printf("%u ", myData.id);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val1);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val2);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val3);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val4);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val5);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val6);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val7);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val8);
  Serial.printf("%.2f ", boardsStruct[myData.id-1].val9);
  Serial.printf("%u ", boardsStruct[myData.id-1].val10);
  Serial.printf("%u ", boardsStruct[myData.id-1].val11);
  Serial.printf("%.u\r ", boardsStruct[myData.id-1].val12);
  
}
 
void setup() {
  //Initialize Serial Monitor
  Serial.begin(115200);
  
  //Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  //Set new MAC Address
   esp_wifi_set_mac(WIFI_IF_STA, &newMACAddress[0]);


  //Init ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  
  // Once ESPNow is successfully Init, we will register for recv CB to
  // get recv packer info
  esp_now_register_recv_cb(OnDataRecv);
}
 
void loop() {
  // Acess the variables for each board
  /*int board1X = boardsStruct[0].x;
  int board1Y = boardsStruct[0].y;
  int board2X = boardsStruct[1].x;
  int board2Y = boardsStruct[1].y;
  int board3X = boardsStruct[2].x;
  int board3Y = boardsStruct[2].y;*/

  //delay(10000);  
}
