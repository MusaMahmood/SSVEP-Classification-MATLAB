clear;clc;close all;
% LOAD TRAINING DATA: (tX, tY);
datach = csvread('Matt_10Hz_null.csv');
rS = 0; %Remove From Start
rE = 0; %Remove From End
datach = datach(rS+1:end-rE,1);
numch = 1;
Fs = 250;
%%-Plot Analysis: %{
winLim = [6 24];
filtch = zeros(size(datach,1),numch);
hannWin = hann(2048); wlen = 1024; h=64; nfft = 4096;
K = sum(hamming(wlen, 'periodic'))/wlen;
for i = 1:numch %     filtch(:,i) = eegcfilt(datach(:,i)); %plot(filtch(:,i));
	filtch(:,i) = customFilt(datach(:,i),Fs,[8 20],3); figure(1); hold on; plot(filtch(:,i));
    [f, P1] = get_fft_data(filtch(:,i),Fs); figure(2);hold on; plot(f,P1),xlim(winLim);
end
figure(3);hold on;%PSD
for i = 1:numch
    [S1,wfreqs] = welch_psd(filtch(:,i), Fs, hannWin);     plot(wfreqs, S1),xlim(winLim);
end
fH = figure(4);hold on; set(fH, 'Position', [0, 0, 1600, 900]);%Spect

for i = 1:numch
    subplot(2,2,i);
    [S1, f1, t1] = stft( filtch(:,i), wlen, h, nfft, Fs ); S2 = 20*log10(abs(S1(f1<winLim(2) & f1>winLim(1),:))/wlen/K + 1e-6); 
    imagesc(t1,f1(f1<winLim(2) & f1>winLim(1)),S2);set(gca,'YDir','normal');xlabel('Time, s');ylabel('Frequency, Hz');colormap(jet)
    cb = colorbar;
    ylabel(cb, 'Power (db)')
    title(['Ch' num2str(i)]);
end
%}
%% Generating Idealized Signals:
len = 1000; % 4 seconds
[sig_ideal_10,T] = testSignal(10.0000,len);
[sig_ideal_12,~] = testSignal(12.5000,len);
[sig_ideal_15,~] = testSignal(15.1515,len);
[sig_ideal_16,~] = testSignal(16.6666,len);
figure(5); hold on; plot(T,sig_ideal_10);plot(T,sig_ideal_12);plot(T,sig_ideal_15);plot(T,sig_ideal_16);ylim([-1.2E-4 1.2E-4]);
%% Feature Extraction: Expanding window method:
close all;clc;
cont = [];
showGraphs = true;
signalDetected = false;
wPlus = 250;        %-% Value by which to increase window length
winJump = 125;      %-% Data points to skip after each iteration. 
maxWinL = 1000;     %-% 5s max
ln = length(datach);
mW = 1:winJump:(ln - maxWinL);
range = 250:60:1500;
ftr=1;
pts = [1, 7935, 15295, 23425];
start = 370;
cWSize = 250;           %-% Start with a window size of 1s
for i = 1:size(range,2)
    fin = start + (range(i)-1);
    fprintf('Current index = [%d to %d]\r\n',start, fin);
    fprintf('length = %d\r\n',range(i));
    for c = 1:numch
        fch = customFilt(datach(start:fin,c),Fs,[8 20],3);
    end
        %%%Feature Extraction: (per channel)
    F(i,:) = fESSVEP(fch,Fs,isempty(cont));
    if isempty(cont)
        commandwindow;
        cont = input('Approve/continue?\n');
        clf(12);
    end
    % Feature selection
end
%% Iterative (Fixed Window) Method: 
%{
close all;clc;
cont = [];
showGraphs = true;
signalDetected = false;
wPlus = 250;        %-% Value by which to increase window length
winJump = 125;      %-% Data points to skip after each iteration. 
maxWinL = 1000;     %-% 5s max
ln = length(datach);
mW = 1:winJump:(ln - maxWinL);
ftr=1;
startPoint = 1;
cWSize = 250;           %-% Start with a window size of 1s
for i=startPoint:length(mW)
    start = mW(i);          %-% Where to start window
    fin   = (mW(i)+(cWSize-1));   %-% Signal ends at start+current Win Length
    fprintf('Current index = [%d to %d]\r\n',start, fin);
    for c = 1:numch
        fch(c,:) = customFilt(datach(start:end,c),Fs,[8 20],3);
    end
        %%%Feature Extraction: (per channel)
    F = fESSVEP(fch(1,:),Fs,true);
    if isempty(cont)
        commandwindow;
        cont = input('Approve/continue?\n');
        clf(12);
    end
    % Feature selection: 1=accept, 9=run entirely, anything else =
    % continue/reject
    if (cont==1)
        tXSSVEP(i,:) = F(i,:);
        tY(i,1) = str2double(CLASS);
        ftr = ftr + 1;
        cont = [];
    else
        tXSSVEP(i,:) = F(i,:);
        tY(i,1) = 0; %REJECT CLASS
    end
    if ~isempty(cont) && cont~=9
        cont = [];
    end
end
%}
%% Classification EOG; 
%{
winSize = 250; %1s:
c=1;
for i = 1:250:length(ch1)-250
    ch1_p = ch1(i:i+249);
    ch2_p = ch2(i:i+249);
    ch3_p = ch3(i:i+249);
    Y(c) = eog_knn(ch1_p,ch2_p,ch3_p);
    c=c+1;
end
%}
%% EOG Classification?:
%{
range = 500:60:2500;
Window = cell(size(range,2),4);
Y = cell(size(range,2),1);
cont = [];
EOGONLY = false;
PLOTDATA = isempty(cont);
OUT = zeros(1,size(range,2));
History = zeros(size(range,2),4);
for i = 1:size(range,2)
    start = 1;
    winEnd = start + (range(i)-1);
    fprintf('Current index = [%d to %d]\r\n',start, winEnd);
    fprintf('Seconds Elapsed = [%1.2f]\r\n',winEnd/250);
    Window{i,1} = ch1( start : winEnd ); % set values:
    Window{i,2} = ch2( start : winEnd );
    Window{i,3} = ch3( start : winEnd );
    Window{i,4} = ch4( start : winEnd );
    [Y{i},F{i}] = fHC(Window{i,1}, Window{i,2}, Window{i,3}, ...
        Window{i,4}, Fs, EOGONLY, PLOTDATA);
    [History(i,:), OUT(i)] = featureAnalysis(F{i},winEnd);
    meanH = mean(History(1:i,:))
    if OUT(i)~=0
        countH(i) = countOccurrences(OUT(:,1:i), OUT(i));
    else
        countH(i) = 0;
    end
    if (max(meanH)>7) && countH(i)>=5
        OUTPROPER(i) = OUT(i);
    else
        OUTPROPER(i) = 0;
    end
    if isempty(cont)
        commandwindow;
        cont = input('Continue? \n');
    end
end
%}
% % EOF
