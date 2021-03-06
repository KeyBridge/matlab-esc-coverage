%%%%Matlab Code to test if SEADLib.dll can use your terrain database

clear;
clc;
close all;

NET.addAssembly(fullfile('C:\USGS', 'SEADLib.dll'));  %%%%%%The location of SEADLib.dll
itmp = ITMAcs.ITMP2P;
TxLat =  41.100946;
TxLon = -97.153371;
RxLat =   40.717130;
RxLon = -94.116746;

TxHtm = 50.0;
RxHtm = 50.0;
Dielectric = 15.0;
Conduct = 0.005;
Refrac = 301.0;
FreqMHz = 3500;
RadClim = int32(5); % 1 Equatorial, 2 Continental Subtorpical, 3 Maritime Tropical, 4 Desert, % 5 Continental Temperate, 6 Maritime Over Land, 7 Maritime Over Sea
Tpol = int32(1); % 0 Horizontal, 1 Vertical
RelPct = 0.5;
ConfPct = 0.5;

tic;
TerHandler = int32(1); % 0 for GLOBE, 1 for USGS 3 sec, 2 for USGS 1 sec
TerDirectory = 'C:\USGS\';
[temp_dBloss]=itmp.ITMp2pAryRels(TxHtm,RxHtm,Refrac,Conduct,Dielectric,FreqMHz,RadClim,Tpol,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
double(temp_dBloss)
if round(double(temp_dBloss),2)==217.79
    'Success'
else
    'Fail'
end
toc;

% % % tic;
% % % TerHandler = int32(2); % 0 for GLOBE, 1 for USGS 3 sec, 2 for USGS 1 sec
% % % TerDirectory='R:\NED1-NED2\NED 1\float';
% % % [temp_dBloss]=itmp.ITMp2pAryRels(TxHtm,RxHtm,Refrac,Conduct,Dielectric,FreqMHz,RadClim,Tpol,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
% % % double(temp_dBloss)
% % % toc;

 
%%%%%%%217.79dB vs 216.77dB
