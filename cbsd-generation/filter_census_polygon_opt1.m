

% Census Tract Filtering in a polygon

function [list_census]=filter_census_polygon_opt1(esc_bound)
    %tic;
    %full_census=xlsread('CensusTractSummaryContinentalUS_nickmod.xlsx');
    load('full_census.mat','full_census')  %x25 Faster Load Time, 0.518 seconds
    min_lat=full_census(:,4);
    max_lat=full_census(:,5);
    min_lon=full_census(:,6);
    max_lon=full_census(:,7);

    %Filter Census Tracks points that are within esc_bound area., 0.1166 seconds
    tf1=inpolygon(min_lon,min_lat,esc_bound(:,2),esc_bound(:,1)); %Check to see if the points are in the polygon
    tf2=inpolygon(max_lon,max_lat,esc_bound(:,2),esc_bound(:,1)); %Check to see if the points are in the polygon
    
    ind1=find(tf1);
    ind2=find(tf2);
    ind3=intersect(ind1,ind2); %Compare tf1 and tf2 and only get ind where both are '1' 
    filter_census=full_census(ind3,:);
    
    ind4=find(filter_census(:,8)>0); %Make sure there is population in the census tract
    filter_census2=filter_census(ind4,:);
    
    [~,ind]=max(horzcat(filter_census2(:,15),filter_census2(:,16),filter_census2(:,17),filter_census2(:,18)),[],2);
    list_census=horzcat(filter_census2(:,2), filter_census2(:,4),filter_census2(:,5),filter_census2(:,6),filter_census2(:,7),filter_census2(:,8),ind); %Add Census Tract GEOID number, minlat, maxlat, minlon, maxlon, and population and type to the list (Classification is 1=Rural, 2=Suburban, 3=Urban, 4=Dense Urban)

    
    %toc; %0.575 Seconds, x10 speed opt
end


