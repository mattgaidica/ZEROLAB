function video2ddt()
[f,p] = uigetfile('*');
[y,Fs]=audioread(fullfile(p,f));
ddt_write_v([fullfile(p,f),'.ddt'],1,length(y),Fs,y(:,1));
% obj = VideoReader(fullfile(p,f))
% figure;
% plot(linspace(0,length(y)/Fs,length(y)),y(:,1))