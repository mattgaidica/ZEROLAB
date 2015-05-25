function analyzePendulum(sessionFile)
videoFPS = 240;
fid = fopen(sessionFile);
sessionInfo = textscan(fid,'%s%s%f','delimiter',',');
fclose(fid);

arduinoData = csvread(sessionInfo{1,1}{1},1,0);
vidRefStartTs = sessionInfo{1,3}(1)/videoFPS;
zAxis = convertAccToG(arduinoData(:,4));

nexfile = [sessionInfo{1,2}{1},'.nex'];
varname='Channel01a';
[n,ts] = nex_ts(nexfile, varname);
tArduino = vidRefStartTs + (arduinoData(:,1)-arduinoData(1,1))/1000;

zAxisDiff = diff(zAxis);
zDiffSpikes = [];
for ii=1:length(ts)
    if ts(ii) > max(tArduino)
        break;
    end
    arduinoIdx = find(tArduino < ts(ii),1,'last');
    if ~isempty(arduinoIdx)
        zDiffSpikes = [zDiffSpikes zAxisDiff(arduinoIdx)];
    end
end

figure('position',[100 100 800 500]);
subplot(211);
h1 = histogram(zDiffSpikes,50);
hold on;
h2 = histogram(zAxisDiff,50);
xlim([-1 1]);
legend('zDiffSpikes','sAxizDiff');

subplot(212);
b = bar(h1.BinEdges(1:end-1),h1.Values-h2.Values);
set(b,'FaceColor',[.7 .2 .2],'EdgeColor','none');
xlim([-1 1]);