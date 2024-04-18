const char ADDRESS_PINS[] = { 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52 };
const char DATA_PINS[] = { 39, 41, 43, 45, 47, 49, 51, 53 };
#define CLOCK 2
#define READ_WRITE 3

#define ERR_ONE 6
#define ERR_TWO 7 

void setup() {
  for (int n = 0; n < 16; n += 1) {
    pinMode(ADDRESS_PINS[n], INPUT);
  }

  for (int n = 0; n < 8; n += 1) {
    pinMode(DATA_PINS[n], INPUT);
  }

  pinMode(CLOCK, INPUT);
  pinMode(READ_WRITE, INPUT);

  pinMode(ERR_ONE, INPUT);
  pinMode(ERR_TWO, INPUT);

  attachInterrupt(digitalPinToInterrupt(CLOCK), printData, RISING);

  Serial.begin(57600);
}

void printData() {
  char hexStorage[4];

  unsigned int address = 0;
  for (int n = 15; n >= 0; n -= 1) {
    int bit = digitalRead(ADDRESS_PINS[n]) ? 1 : 0;
    Serial.print(bit);
    address = (address << 1) + bit;
  }
  sprintf(hexStorage, "%04x", address);
  Serial.print("  ");
  Serial.print(hexStorage);

  Serial.print("  |  ");

  unsigned int data = 0;
  for (int n = 7; n >= 0; n -= 1) {
    int bit = digitalRead(DATA_PINS[n]) ? 1 : 0;
    Serial.print(bit);
    data = (data << 1) + bit;
  }
  sprintf(hexStorage, "%02x %c", data, digitalRead(READ_WRITE) ? 'r' : 'W');
  Serial.print("  ");
  Serial.print(hexStorage);

  // if (digitalRead(ERR_ONE) != digitalRead(ERR_TWO)) {
  //   Serial.print("   ERR!");
  // }

  Serial.println();
}

void loop() { }
