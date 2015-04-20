function zAxis = convertAccToG(zAxis)
raw1g = 637;
raw0g = 539;
zAxis = (zAxis-raw0g)/(raw1g-raw0g);