clear;
clc;
close all;

rand_seed=1; %For Repeatability, Increment for different CBSD deployments
rng(rand_seed);%Set Random Seed


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Folder (will need to change)
Zdrive_folder='Z:\MATLAB\3.5GHz\CBSD_Generation_Code';
cd(Zdrive_folder)
addpath(Zdrive_folder);
pause(0.1);

%%%%%%%%%%%%Load DPAs
load('mod_dpa_poly_east.mat','mod_dpa_poly_east') %%%East Coast DPAs
load('mod_dpa_poly_west.mat','mod_dpa_poly_west') %%%West Coast DPAs

%%%%%%%%%%%%Load 10km Inner Line, Roughly 1km spacing along coast
load('downsampled_east10km.mat','downsampled_east10km') 
load('downsampled_west10km.mat','downsampled_west10km') 

%%%%%%%%%%%%%%%%%%%%Plot to Show DPA Number
close all;
figure;
hold on;
for i=1:1:length(mod_dpa_poly_west)
    temp_dpa=mod_dpa_poly_west{i};
    plot(temp_dpa(:,2),temp_dpa(:,1),'-g')
    text(nanmean(temp_dpa(:,2)),nanmean(temp_dpa(:,1)),num2str(i))
end
for i=1:1:length(mod_dpa_poly_east) %%%%%%New York DPA is #7
    temp_dpa=mod_dpa_poly_east{i};
    plot(temp_dpa(:,2),temp_dpa(:,1),'-g')
    text(nanmean(temp_dpa(:,2)),nanmean(temp_dpa(:,1)),num2str(i))
end
plot(downsampled_east10km(:,2),downsampled_east10km(:,1),'-b')
plot(downsampled_west10km(:,2),downsampled_west10km(:,1),'-b')
grid on;


%%%%%%%%%%%%%%%%%%%%%%% Folder Name Variables
data_label1='Norfolk_Example';
%data_label1='LA_Example';
sim_number=0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%Create Folder
tempfolder=strcat(data_label1,'_Sim',num2str(sim_number));
mkdir(tempfolder)
sim_folder=strcat(Zdrive_folder,'\',tempfolder);
cd(sim_folder)
pause(0.1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Parameters For Generating CBSDs
catb_radius=600; %[km] 
cata_radius=200; %[km] 

%%%%%%%%%%%%%%%%%%%%%%%sim_pts can be a single lat/lon or an array of lat/lon (DPA)
sim_pts=mod_dpa_poly_east{1}; %Norfolk (Lat/Lon) 
%sim_pts=mod_dpa_poly_west{13}; %LA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%Step1: Generate CBSDs around the sim_pt(s) 
tic;
generate_cbsds_dist_deployment_sort(sim_pts,catb_radius,cata_radius) %Also saves CBSD lists as a .csv
toc; 

load('list_cbsd_cata_azi.mat','list_cbsd_cata_azi'); %lat, lon, height [m], classification (Rural=1,Suburban=2,Urban=3,Dense Urban=4), EIRP [dBm], NaN, NaN, Nan
load('list_cbsd_catb_azi.mat','list_cbsd_catb_azi'); %lat, lon, height [m], classification (Rural=1,Suburban=2,Urban=3,Dense Urban=4), EIRP [dBm], Azi1,Azi2,Azi3
[CatA_size,~]=size(list_cbsd_cata_azi) %Norfolk 200km: 19,852
[CatB_size,~]=size(list_cbsd_catb_azi) %Norfolk 600km: 18,858 

%%%%CatA have omni directional antennas.
%%%%CatB can have 3 sectors with suggested 65 deg beamwidth (ITU-R M.2292 - F.1336)
%%%%Ignore CatB Azimuths for Omni Directional 
%%%%CatB classification can be used for multiple things:
%%%%1. CBSD downtilt (Rural=3deg, Suburban=6deg, Urban=10deg)
%%%%2. E-Hata































