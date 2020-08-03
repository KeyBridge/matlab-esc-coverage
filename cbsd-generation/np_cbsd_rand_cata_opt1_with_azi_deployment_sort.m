%%%% CBSD Randomization

function np_cbsd_rand_cata_opt1_with_azi_deployment_sort
load('list_census_cata.mat','list_census_cata')

%CAT A
cata_eirp=26; %CatA 26dBm;

%Dense Urban Antenna Height
anthp1_dur=0.5;
anth_dur_r1=3;
anth_dur_r2=15;
anthp2_dur=0.25;
anth_dur_r3=18;
anth_dur_r4=30;
anthp3_dur=0.25;
anth_dur_r5=33;
anth_dur_r6=60;

% Urban Antenna Height
anthp1_urb=0.5;  %Antenna Height-Urban-Min-Percentage 50 Percent
anth_urb_r1=6; % Antenna Height-Urban Min 3 meters
anth_urb_r2=18;
anthp2_urb=0.5; 
anth_urb_r3=3; 

% Suburban Antenna Height
anthp1_sub=0.3; %Antenna Height-Suburban- Percentage
anth_sub_r1=6; 
anth_sub_r2=12;
anthp2_sub=0.7;
anth_sub_r3=3;

% Rural Antenna Height
anthp1_rur=0.2;	%Antenna Height-Rural-Percentage 20 Percent
anth_rur_r1=6;  % Antenna Height-Rural Min 6 meters
anthp2_rur=0.8;
anth_rur_r2=3;  % Antenna Height-Rural Max 6 meters

% CAT A: Other Parameters
mark_pen=0.2; % Market Penetration 20 Percent
chan_scaling=0.1; %Channel Scaling 10 Percent
urb_comm_adjust=1.31; %Daytime Commuter Adjustment-Urban
comm_adjust=1; %Daytime Commuter Adjustment-Suburban/Rural
urb_user_ap=50; %Number of Users per AP-Urban
sub_user_ap=20; %Number of Users per AP-Suburban
rur_user_ap=3; %Number of Users per AP-Rural

%Percentage Served Cat A vs Cat B
urb_served=0.8; % 80 Percent served by category A
sub_served=0.6; % 60 Percent served by category A
rur_served=0.4; % 40 Percent served by category A
%Remaining are served by Cat B

%Randomly spread 3.5 GHz CBSD around census tracts and associated with nearest ESC. 

% Place APs due to a Uniform Distribution, some APs will land outside of tract.

%Preallocate for speed
list_cbsd_cata=NaN(20000,9);
lat_lon_limits=NaN(20000,4); 

%%%Step 1: Find the Total Number of CBSDs 
%tic;
marker_cata=1;
for i=1:1:length(list_census_cata(:,1))
    pop_class=list_census_cata(i,7);
    if pop_class==4 %'dense urban'
        temp_users=ceil((list_census_cata(i,6)*mark_pen*chan_scaling*urb_comm_adjust)); %Number of Users
        cata_temp_ap=ceil(temp_users*urb_served/(urb_user_ap)); %Number of Cat A Access Points
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,4)=4;
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,9)=list_census_cata(i,6); %%%Save the Population
        lat_lon_limits(marker_cata:marker_cata+cata_temp_ap-1,:)=repmat(list_census_cata(i,2:5),cata_temp_ap,1);
        marker_cata=marker_cata+cata_temp_ap; 
    elseif pop_class==3  %'Urban' 
        temp_users=ceil((list_census_cata(i,6)*mark_pen*chan_scaling*urb_comm_adjust)); %Number of Users
        cata_temp_ap=ceil(temp_users*urb_served/(urb_user_ap)); %Number of Cat A Access Points
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,4)=3;
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,9)=list_census_cata(i,6); %%%Save the Population
        lat_lon_limits(marker_cata:marker_cata+cata_temp_ap-1,:)=repmat(list_census_cata(i,2:5),cata_temp_ap,1);
        marker_cata=marker_cata+cata_temp_ap;        
    elseif pop_class==2   %'Suburban' 
        temp_users=ceil((list_census_cata(i,6)*mark_pen*chan_scaling*comm_adjust)); %Number of Suburan Users
        cata_temp_ap=ceil(temp_users*sub_served/(sub_user_ap)); %Number of Cat A Access Points
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,4)=2;
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,9)=list_census_cata(i,6); %%%Save the Population
        lat_lon_limits(marker_cata:marker_cata+cata_temp_ap-1,:)=repmat(list_census_cata(i,2:5),cata_temp_ap,1);
        marker_cata=marker_cata+cata_temp_ap;
    elseif pop_class==1  %'Rural'  
        temp_users=ceil((list_census_cata(i,6)*mark_pen*chan_scaling*comm_adjust)); %Number of Suburan Users
        cata_temp_ap=ceil(temp_users*rur_served/(rur_user_ap)); %Number of Cat A Access Points
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,4)=1;
        list_cbsd_cata(marker_cata:marker_cata+cata_temp_ap-1,9)=list_census_cata(i,6); %%%Save the Population
        lat_lon_limits(marker_cata:marker_cata+cata_temp_ap-1,:)=repmat(list_census_cata(i,2:5),cata_temp_ap,1);
        marker_cata=marker_cata+cata_temp_ap;
    end
end  

%CUT NaN off of list_cbsd_cata
temp_list=list_cbsd_cata(1:marker_cata-1,:);
clear list_cbsd_cata;
list_cbsd_cata=temp_list;
[x1,~]=size(list_cbsd_cata);

temp_lat_lon=lat_lon_limits(1:marker_cata-1,:);
clear lat_lon_limits;
lat_lon_limits=temp_lat_lon;

lat_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon
lon_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon
ant_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon

%%%%EIRP
list_cbsd_cata(:,5)=cata_eirp;

%%%Randomize Lat/Lon
list_cbsd_cata(:,1)=lat_rand.*(lat_lon_limits(:,2)-lat_lon_limits(:,1))+lat_lon_limits(:,1); %(max_lat-min_lat)/2+min_lat;
list_cbsd_cata(:,2)=lon_rand.*(lat_lon_limits(:,4)-lat_lon_limits(:,3))+lat_lon_limits(:,3); %For Category B

rural_idx=find(list_cbsd_cata(:,4)==1); %Rural Idx
suburban_idx=find(list_cbsd_cata(:,4)==2); %Sub Idx
urban_idx=find(list_cbsd_cata(:,4)==3); %Urban Idx
den_idx=find(list_cbsd_cata(:,4)==4); %Dense Urban Idx

%%%Rural  %Category A
list_cbsd_cata(rural_idx,3)=anth_rur_r1;  %20 Percent of Antenna Height is 6 meters (set all to 6m, then reset others to 3m)
idx_anth_rur_r2=find(ant_rand(rural_idx)<=anthp2_rur); %80 Percent of Antenna Height is 3 meters 
list_cbsd_cata(rural_idx(idx_anth_rur_r2),3)=anth_rur_r2;  %3 meters
        
            
%%%Suburban  %Category A
list_cbsd_cata(suburban_idx,3)=anth_sub_r3;  %70 Percent of Antenna Height is 3 meters (set all to 3m, then reset others to 6-12m)
idx_anth_sub_r2=find(ant_rand(suburban_idx)>anthp2_sub);
list_cbsd_cata(suburban_idx(idx_anth_sub_r2),3)=round((anth_sub_r2-anth_sub_r1)/(anthp1_sub)*(ant_rand(suburban_idx(idx_anth_sub_r2))-anthp2_sub)+anth_sub_r1); %6 to 12 meters	

%%%Urban
list_cbsd_cata(urban_idx,3)=anth_urb_r3;  %50 Percent of Antenna Height is 3 meters (set all to 3m, then reset others)
idx_anth_urb_r2=find(ant_rand(urban_idx)>anthp2_urb);
list_cbsd_cata(urban_idx(idx_anth_urb_r2),3)=round((anth_urb_r2-anth_urb_r1)/(anthp1_urb)*(ant_rand(urban_idx(idx_anth_urb_r2))-anthp2_urb)+anth_urb_r1); %6 to 18 meters	

%%%Dense Urban
idx_anth_dur_r1=find(ant_rand(den_idx)<=anthp1_dur); %50 Percent of Antenna Height is 3-15 meters
list_cbsd_cata(den_idx(idx_anth_dur_r1),3)=round((anth_dur_r2-anth_dur_r1)/(anthp1_dur)*(ant_rand(den_idx(idx_anth_dur_r1)))+anth_dur_r1); %3-15 meters	

idx_anth_dur_r2=find(ant_rand(den_idx)>anthp1_dur & ant_rand(den_idx)<=anthp1_dur+anthp2_dur); %25 Percent of Antenna Height  18 to 30 meters
list_cbsd_cata(den_idx(idx_anth_dur_r2),3)=round((anth_dur_r4-anth_dur_r3)/(anthp2_dur)*(ant_rand(den_idx(idx_anth_dur_r2))-anthp1_dur)+anth_dur_r3); % 18 to 30 meters	

idx_anth_dur_r3=find(ant_rand(den_idx)>anthp1_dur+anthp2_dur); %25 Percent of Antenna Height 33 to 60 meters
list_cbsd_cata(den_idx(idx_anth_dur_r3),3)=round((anth_dur_r6-anth_dur_r5)/(anthp3_dur)*(ant_rand(den_idx(idx_anth_dur_r3))-(anthp1_dur+anthp2_dur))+anth_dur_r5); %33 to 60 meters	

%toc; %0.028 Seconds, dramatic cut from  Original 

list_cbsd_cata_azi=list_cbsd_cata;
list_cbsd_cata_azi(:,6:8)=NaN(1); %NaN equates to an omni directional antenna

[~,idx_sort] = sort(list_cbsd_cata_azi(:,9),'descend'); %Sort Based upon Population

temp_sort_list=list_cbsd_cata_azi(idx_sort,:);
clear list_cbsd_cata_azi;
list_cbsd_cata_azi=temp_sort_list;


%save('list_cbsd_cata.mat','list_cbsd_cata');
save('list_cbsd_cata_azi.mat','list_cbsd_cata_azi');

cata_table=table(list_cbsd_cata_azi);
writetable(cata_table,'list_cata.csv')


end








