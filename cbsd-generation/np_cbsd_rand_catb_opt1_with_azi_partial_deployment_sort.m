
function np_cbsd_rand_catb_opt1_with_azi_partial_deployment_sort

load('list_census_catb.mat','list_census_catb')
   
catb_eirp_sub=47; %CatB Suburban/Rural EIRP 47dBm;
catb_eirp_urb1=40;  %EIRP level for outdoor Category B APs are 40 dBm to 47 dBm (Uniform Distribution) for Urban area.
catb_eirp_urb2=47;

%CAT B Parameters
%Suburan/Rural (Uniform Distirubtion) 
catb_anth_sub_r1=6; %6 meters (Uniform Distirubtion)
catb_anth_sub_r2=100; %100 meters

%Urban/Dense Urban (Uniform Distirubtion)
catb_anth_urb_r1=6; %6 meters
catb_anth_urb_r2=30; %30 meters

% CAT B: Other Parameters
chan_scaling=0.1; %Channel Scaling 10 Percent
catb_urb_user_ap=200; %Number of Users per AP-Urban
catb_sub_user_ap=200; %Number of Users per AP-Suburban
catb_rur_user_ap=500; %Number of Users per AP-Rural

mark_pen=0.2; % Market Penetration 20 Percent
urb_comm_adjust=1.31; %Daytime Commuter Adjustment-Urban
comm_adjust=1; %Daytime Commuter Adjustment-Suburban/Rural

%Percentage Served Cat A vs Cat B
urb_served=0.8; % 80 Percent served by category A
sub_served=0.6; % 60 Percent served by category A
rur_served=0.4; % 40 Percent served by category A
%Remaining are served by Cat B

%Randomly spread 3.5 GHz CBSD around census tracts and associated with nearest ESC. 

% Place APs due to a Uniform Distribution, some APs will land outside of tract.

%Preallocate for speed
list_cbsd_catb=NaN(20000,9);
lat_lon_limits=NaN(20000,4); 

%%%Step 1: Find the Total Number of CBSDs 
%tic;
marker_catb=1;
for i=1:1:length(list_census_catb(:,1))
    pop_class=list_census_catb(i,7);
    if pop_class==4 %'dense urban'
        temp_users=ceil((list_census_catb(i,6)*mark_pen*chan_scaling*urb_comm_adjust)); %Number of Users
        catb_temp_ap=ceil(temp_users*(1-urb_served)/catb_urb_user_ap); %Number of Cat B Access Points
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,4)=4;
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,9)=list_census_catb(i,6); %%%Save the Population
        lat_lon_limits(marker_catb:marker_catb+catb_temp_ap-1,:)=repmat(list_census_catb(i,2:5),catb_temp_ap,1);
        marker_catb=marker_catb+catb_temp_ap; 
    elseif pop_class==3  %'Urban' 
        temp_users=ceil((list_census_catb(i,6)*mark_pen*chan_scaling*urb_comm_adjust)); %Number of Users
        catb_temp_ap=ceil(temp_users*(1-urb_served)/catb_urb_user_ap); %Number of Cat B Access Points
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,4)=3;
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,9)=list_census_catb(i,6); %%%Save the Population
        lat_lon_limits(marker_catb:marker_catb+catb_temp_ap-1,:)=repmat(list_census_catb(i,2:5),catb_temp_ap,1);
        marker_catb=marker_catb+catb_temp_ap;        
    elseif pop_class==2   %'Suburban' 
        temp_users=ceil((list_census_catb(i,6)*mark_pen*chan_scaling*comm_adjust)); %Number of Suburan Users
        catb_temp_ap=ceil(temp_users*(1-sub_served)/catb_sub_user_ap); %Number of Cat B Access Points
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,4)=2;
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,9)=list_census_catb(i,6); %%%Save the Population
        lat_lon_limits(marker_catb:marker_catb+catb_temp_ap-1,:)=repmat(list_census_catb(i,2:5),catb_temp_ap,1);
        marker_catb=marker_catb+catb_temp_ap;
    elseif pop_class==1  %'Rural'  
        temp_users=ceil((list_census_catb(i,6)*mark_pen*chan_scaling*comm_adjust)); %Number of Rural Users
        catb_temp_ap=ceil(temp_users*(1-rur_served)/catb_rur_user_ap); %Number of Cat B Access Points
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,4)=1;
        list_cbsd_catb(marker_catb:marker_catb+catb_temp_ap-1,9)=list_census_catb(i,6); %%%Save the Population
        lat_lon_limits(marker_catb:marker_catb+catb_temp_ap-1,:)=repmat(list_census_catb(i,2:5),catb_temp_ap,1);
        marker_catb=marker_catb+catb_temp_ap;
    end
end  

%CUT NaN off of list_cbsd_cata
temp_list=list_cbsd_catb(1:marker_catb-1,:);
clear list_cbsd_catb;
list_cbsd_catb=temp_list;
[x1,~]=size(list_cbsd_catb);

temp_lat_lon=lat_lon_limits(1:marker_catb-1,:);
clear lat_lon_limits;
lat_lon_limits=temp_lat_lon;
[x2,~]=size(list_cbsd_catb);

lat_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon
lon_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon
ant_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon
eirp_rand=rand(x1,1); %Randomization for Antenna Height and Lat/Lon

%%%Randomize Lat/Lon
list_cbsd_catb(:,1)=lat_rand.*(lat_lon_limits(:,2)-lat_lon_limits(:,1))+lat_lon_limits(:,1); %(max_lat-min_lat)/2+min_lat;
list_cbsd_catb(:,2)=lon_rand.*(lat_lon_limits(:,4)-lat_lon_limits(:,3))+lat_lon_limits(:,3); %For Category B

rural_idx=find(list_cbsd_catb(:,4)==1); %Rural Idx
suburban_idx=find(list_cbsd_catb(:,4)==2); %Sub Idx
urban_idx=find(list_cbsd_catb(:,4)==3); %Urban Idx
den_idx=find(list_cbsd_catb(:,4)==4); %Dense Urban Idx

%%%Rural
list_cbsd_catb(rural_idx,3)=round((catb_anth_sub_r2-catb_anth_sub_r1)*(ant_rand(rural_idx))+catb_anth_sub_r1);  
list_cbsd_catb(rural_idx,5)=catb_eirp_sub;

%%%Suburban
list_cbsd_catb(suburban_idx,3)=round((catb_anth_sub_r2-catb_anth_sub_r1)*(ant_rand(suburban_idx))+catb_anth_sub_r1);   
list_cbsd_catb(suburban_idx,5)=catb_eirp_sub;

%%%Urban
list_cbsd_catb(urban_idx,3)=round((catb_anth_urb_r2-catb_anth_urb_r1)*(ant_rand(urban_idx))+catb_anth_urb_r1);   
list_cbsd_catb(urban_idx,5)=round((catb_eirp_urb2-catb_eirp_urb1)*eirp_rand(urban_idx)+catb_eirp_urb1);

%%%Dense Urban
list_cbsd_catb(den_idx,3)=round((catb_anth_urb_r2-catb_anth_urb_r1)*(ant_rand(den_idx))+catb_anth_urb_r1);   
list_cbsd_catb(den_idx,5)=round((catb_eirp_urb2-catb_eirp_urb1)*eirp_rand(den_idx)+catb_eirp_urb1);
%toc; %0.066 Seconds, dramatic cut from  Original Time of 41 Seconds, Size 8559


%%%%%%%%%%%%For CatB CBSDs, include Azimuth

azi_rand=round(rand(x1,1)*360);
three_azi=mod(horzcat(azi_rand,azi_rand+120,azi_rand+240),360); %%%Three Azimuths

list_cbsd_catb_azi=list_cbsd_catb;
list_cbsd_catb_azi(:,6:8)=three_azi;

[~,idx_sort] = sort(list_cbsd_catb_azi(:,9),'descend'); %Sort Based upon Population

temp_sort_list=list_cbsd_catb_azi(idx_sort,:);
clear list_cbsd_catb_azi;
list_cbsd_catb_azi=temp_sort_list;

%save('list_cbsd_catb.mat','list_cbsd_catb');
save('list_cbsd_catb_azi.mat','list_cbsd_catb_azi');


catb_table=table(list_cbsd_catb_azi);
writetable(catb_table,'list_catb.csv')

end



