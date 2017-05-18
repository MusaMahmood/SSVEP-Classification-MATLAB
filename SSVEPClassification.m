%% SSVEP CLASSIFICATION:
clear;clc;close all;
% LOAD TRAINING DATA: (tX, tY);
DATA = csvread('Matt_10Hz_null.csv');
Fs = 250;
% Generating Idealized Signals:
clear sig_ideal;
len = 5000; % 4s = testSignal(desiredF,ln,amplitude,Fs);
f = [0.0000, 10.0000,12.5000,15.1515,16.6667];
sig_ideal = zeros(4,len);
X_samples = DATA(:,1);
for i = 1:length(f)
    [sig_ideal(i,:),T,sig_h1(i,:),sig_h2(i,:),SQW(i,:)] = testSignal(f(i),len);
%     figure(5); hold on; plot(T,sig_ideal(i,:)); ylim([-1.2E-4 1.2E-4]);
end
% Some signal manipulation:
for i=1:length(f)
    X_filt = customFilt(X_samples,Fs,[8 20],3);
    conv0(i,:) = conv(X_filt(1:10000),sig_ideal(i,:)+(rand(1)-0.5)*0.000015,'full');
    conv1(i,:) = conv(X_samples,sig_h1(i,:));
    conv2(i,:) = conv(X_samples,sig_h2(i,:));
%     conv1(i,:) = conv(X_samples,SQW(i,:));
%     TODO: TAKE AVERAGE P2P ACROSS SIGNAL (ALSO TRY PEAK2RMS)
%     c0p2p(i) = peak2peak(conv0(i,1:1000));
end
% Analysis:
% clf(4);
fH = figure(4); hold on; set(fH, 'Position', [0, 0, 1600, 900]);%Spect
hannW = hannWin(2048);winLim = [6 24];
wlen = 1024; h=64; nfft = 4096;
K = sum(hamming(wlen, 'periodic'))/wlen;
for i = 1:5
    [S1 ,wfreqs] = welch_psd(conv0(i,:), Fs, hannW); figure(4); hold on; plot(wfreqs, S1),xlim(winLim);
    [f, P1] = get_fft_data(conv0(i,:)',Fs); figure(2);hold on; plot(f,P1),xlim(winLim);
    figure; [S1, f1, t1] = stft( conv0(i,:), wlen, h, nfft, Fs ); S2 = 20*log10(abs(S1(f1<winLim(2) & f1>winLim(1),:))/wlen/K + 1e-6); 
    imagesc(t1,f1(f1<winLim(2) & f1>winLim(1)),S2);set(gca,'YDir','normal');xlabel('Time, s');ylabel('Frequency, Hz');colormap(jet);cb = colorbar;ylabel(cb, 'Power (db)')
end


%% Feature Extraction: Expanding window method:
% Todo move to separate function 
close all;clc;
range = 250:60:2500;
F = []; F1 = [];
filtRange = [8 20];
for i = 1:5
    F0{i} = featureExtractionSSVEP(sig_ideal(i,:),range,filtRange,[0]);
%     F1{i} = featureExtractionSSVEP(sig_h1(i,:),range,filtRange,0);
%     F2{i} = featureExtractionSSVEP(sig_h2(i,:),range,filtRange,0);
    FF{i} = [F0{i}(:,5:8),F0{i}(:,13:16),F0{i}(:,21:24)];
    FF{i}(:,end+1) = i-1;
%     F = [F; featureExtractionSSVEP(sig_ideal(i,:),range,filtRange,0)];
end
FALL = [FF{1};FF{2};FF{3};FF{4};FF{5}];

%% Feature Extraction for Signal
F_s = featureExtractionSSVEP(X_samples, range, filtRange, [1]);
F_s2 = [F_s(:,5:8),F_s(:,13:16),F_s(:,21:24)];
for i = 1:size(F_s,1)
    Y(i) = knn(F_s2(i,:),FALL(:,1:end-1),FALL(:,end),1);
end
%% CCA
% load carbig;
% X = [Displacement Horsepower Weight Acceleration MPG];
% nans = sum(isnan(X),2) > 0;
% [A,B,r,U,V] = CCA(X(~nans,1:3),X(~nans,4:5));
% Compare to each 
%{
for i = 1:5
    start = 1+(i-1)*38;
    [~,~,~,U{i},V{i}] = CCA(F_s2, F1{i});
    if~isempty(U{i})
        figure
        plot(U{i}(:,1),V{i}(:,1),'.r')
    end
end
%}
% plot(U(:,1),V(:,1),'.')
