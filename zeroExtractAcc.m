%millis,xVal,yVal,zVal,vcc
function csvdata = zeroExtractAcc()
[f,p] = uigetfile('*.csv');
csvdata = csvread(fullfile(p,f),1,0);

figure;
raw1g = 637;
raw0g = 539;
plot((csvdata(:,1)-csvdata(1,1))/1000,(csvdata(:,4)-raw0g)/(raw1g-raw0g));