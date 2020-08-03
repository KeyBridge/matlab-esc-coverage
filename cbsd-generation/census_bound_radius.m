function [census_bound] = census_bound_radius(list_esc,radius) 

    %Draw circles around list_esc points and use that as the boundary for the esc filter/census filter.  
    %%%Take out NaN
    idx_nan=find(isnan(list_esc(:,1)));
    
    if isempty(idx_nan)==1
        nan_list_esc=list_esc;
    else
        nan_list_esc=list_esc(1:idx_nan(1)-1,:);
    end
    
    %Go inland from all points and include those in a bigger polygon to be included for the census tracs polygon
    az=[];
    ellipsoid=[];
    n_pts=50;
    [x1,y1]=size(nan_list_esc);
    %Preallocate
    temp_esc_lat=NaN(n_pts,x1);
    temp_esc_lon=NaN(n_pts,x1);
    for i=1:1:x1
        [temp_esc_lat(:,i), temp_esc_lon(:,i)]=scircle1(nan_list_esc(i,1),nan_list_esc(i,2),km2deg(radius),az,ellipsoid,'degrees',n_pts);
    end
    esc_lat2=reshape(temp_esc_lat,[],1);
    esc_lon2=reshape(temp_esc_lon,[],1);
    
    esc_lat3=esc_lat2(~isnan(esc_lat2));
    esc_lon3=esc_lon2(~isnan(esc_lon2));
    
    k=convhull(esc_lon3,esc_lat3);
    esc_lat4=esc_lat3(k);
    esc_lon4=esc_lon3(k);
    census_bound=[esc_lat4,esc_lon4];
    
end