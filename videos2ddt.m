function videos2ddt()
videoDir = uigetdir;
movieFiles = dir(fullfile(videoDir,'*.MOV'));
for ii=1:length(movieFiles)
    disp(['Converting ',movieFiles(ii).name]);
    [y,Fs] = audioread(fullfile(videoDir,movieFiles(ii).name));
    ddt_write_v([fullfile(videoDir,movieFiles(ii).name),'.ddt'],1,length(y),Fs,y(:,1));
end