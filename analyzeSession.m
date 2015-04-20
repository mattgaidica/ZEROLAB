% session cell: arduinoLogFile, videoFile, videoSyncFrame, nexFile
% identify advent of sync LED in video frame externally, note it in CSV
% 1) arduino z-axis 2) raw data epochs 3) hist
% 

function spikeFreq=analyzeSession(videoFPS)
[f,p] = uigetfile('*.csv');
fid = fopen(fullfile(p,f));
sessionInfo = textscan(fid,'%s%s%f','delimiter',',');
fclose(fid);

for ii=1:length(sessionInfo{1})
    %z-axis data
    arduinoData = csvread(sessionInfo{1,1}{ii},1,0);
    zAxis = convertAccToG(arduinoData(:,4));
    h=figure('position',[500 500 900 300]);
    plot(zAxis);
    zoom on;
    waitfor(gcf,'CurrentCharacter',char(13)); %wait for enter
    zoom reset;
    zoom off;
    [zAxisInflects,~] = ginput(3); %select start, weightless, end
    disp(zAxisInflects);
    close(h);
    zAxisInflectsTs = (arduinoData(round(zAxisInflects),1) - arduinoData(1,1))/1000; %convert to sec
    zerogInterval = zAxisInflectsTs(3) - zAxisInflectsTs(1);
    
    %movie data
    [y,Fs] = audioread(sessionInfo{1,2}{ii});
    vidRefStartTs = sessionInfo{1,3}(1)/videoFPS;
    zerogStartTs = vidRefStartTs + zAxisInflectsTs(1) - zerogInterval;
    zerogEndTs = vidRefStartTs + zAxisInflectsTs(3) + zerogInterval;
    
    h = figure('position',[500 500 900 900]);
    
    hs(1) = subplot(3,1,1);
    zerogIntervalSamples = zAxisInflects(3)-zAxisInflects(1);
    zAxisIdxStart = zAxisInflects(1)-zerogIntervalSamples;
    zAxisIdxEnd = zAxisInflects(3)+zerogIntervalSamples;
    plot(linspace(-zerogInterval,zerogInterval*2,length(zAxis(zAxisIdxStart:zAxisIdxEnd))),...
        zAxis(zAxisIdxStart:zAxisIdxEnd));
    ylim([-.5 3]);
    xlim([-zerogInterval zerogInterval*2]);
    hold on;
    plot([0 0],[-3 3],'--','color','k');
    plot([zerogInterval zerogInterval],[-.5 3],'--','color','k');
    xlabel('time (s)');
    ylabel('g');
    
    %nex
    nexfile = [sessionInfo{1,2}{ii},'.nex'];
%     [nvar, names, types] = nex_info(nexfile);
    varname='Channel01a';
    [n, ts] = nex_ts(nexfile, varname);
    intervalTsIdx = find(ts >= zerogStartTs & ts < zerogEndTs);
    
    hs(2) = subplot(3,1,2);
    plot(linspace(-zerogInterval,zerogInterval*2,length(y(round(zerogStartTs*Fs):round(zerogEndTs*Fs)))),...
        y(round(zerogStartTs*Fs):round(zerogEndTs*Fs)));
    hold on;
    for jj=1:length(intervalTsIdx)
        plot([ts(intervalTsIdx(jj))-zerogStartTs-zerogInterval ts(intervalTsIdx(jj))-zerogStartTs-zerogInterval],[-.3 .3],'r');
    end
    xlim([-zerogInterval zerogInterval*2]);
    plot([0 0],[-1 1],'--','color','k');
    plot([zerogInterval zerogInterval],[-1 1],'--','color','k');
    xlabel('time (s)');
    ylabel('amplitude');
    legend('raw','raster');
    
    hs(3) = subplot(3,1,3);
    histBin = 20;
    [counts,centers] = hist(ts(intervalTsIdx)-zerogStartTs-zerogInterval,histBin);
    binWidthTs = (zerogInterval*3)/histBin;
    counts = counts/binWidthTs;
    bar(centers,counts);
    hold on;
    xlim([-zerogInterval zerogInterval*2]);
    plot([0 0],[0 max(counts)],'--','color','k');
    plot([zerogInterval zerogInterval],[0 max(counts)],'--','color','k');
    ylim([0 max(counts)]);
    xlabel('time (s)');
    ylabel('spikes/s');
    
    linkaxes(hs,'x');
    
    %output data
    spikeFreq(1) = length(find(ts >= zerogStartTs & ts < zerogStartTs+zerogInterval))/zerogInterval; %before
    spikeFreq(2) = length(find(ts >= zerogStartTs+zerogInterval & ts < zerogEndTs-zerogInterval))/zerogInterval; %during
    spikeFreq(3) = length(find(ts >= zerogEndTs-zerogInterval & ts < zerogEndTs))/zerogInterval; %after
    
    disp('end');
end