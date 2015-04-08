int zAxis = A0;
int yAxis = A1;
int xAxis = A2;
int zVal = 0;
int yVal = 0;
int xVal = 0;

void setup() {
  Serial.begin(9600);
  analogReference(EXTERNAL);
}

void loop() {
  zVal = analogRead(zAxis);
  yVal = analogRead(yAxis);
  xVal = analogRead(xAxis);
  Serial.print(zVal);
  Serial.print("\t");
  Serial.print(yVal);
  Serial.print("\t");
  Serial.println(xVal);
  
  delay(50);
}
