function generate_cbsds_dist_deployment_sort(sim_pts,catb_radius,cata_radius)

%Draw circles around list_esc_ship_radius and use that as the boundary for the census filter.  
[census_bound_catb]=census_bound_radius(sim_pts,catb_radius);
save('census_bound_catb.mat','census_bound_catb')
%load('census_bound_catb.mat','census_bound_catb')


%Draw circles around list_esc_ship_radius and use that as the boundary for the census filter.  
[census_bound_cata]=census_bound_radius(sim_pts,cata_radius);
save('census_bound_cata.mat','census_bound_cata')
%load('census_bound_cata.mat','census_bound_cata')


% figure
% hold on;
% plot(census_bound_catb(:,2),census_bound_catb(:,1),'y')
% plot(census_bound_cata(:,2),census_bound_cata(:,1),'g')
% plot(sim_pts(:,2),sim_pts(:,1),'-k')
% grid on;


%Census tract filtering Cat B
[list_census_catb]=filter_census_polygon_opt1(census_bound_catb);
save('list_census_catb.mat','list_census_catb')
%load('list_census_catb.mat','list_census_catb')

%Census tract filtering Cat A
[list_census_cata]=filter_census_polygon_opt1(census_bound_cata);
save('list_census_cata.mat','list_census_cata')
%load('list_census_cata.mat','list_census_cata')


% figure
% hold on;
% plot(census_bound_catb(:,2),census_bound_catb(:,1),'-y')
% plot(census_bound_cata(:,2),census_bound_cata(:,1),'-g')
% plot(list_census_catb(:,4),list_census_catb(:,2),'oc')
% plot(list_census_cata(:,4),list_census_cata(:,2),'om')
% plot(sim_pts(:,2),sim_pts(:,1),'-k')
% grid on;



%CBSD Randomization
np_cbsd_rand_cata_opt1_with_azi_deployment_sort;
np_cbsd_rand_catb_opt1_with_azi_partial_deployment_sort;
load('list_cbsd_cata_azi.mat','list_cbsd_cata_azi');
load('list_cbsd_catb_azi.mat','list_cbsd_catb_azi');



%close all;
figure
hold on;
plot(list_cbsd_cata_azi(:,2),list_cbsd_cata_azi(:,1),'og','MarkerSize',1)
plot(list_cbsd_catb_azi(:,2),list_cbsd_catb_azi(:,1),'oc','MarkerSize',1)
plot(census_bound_catb(:,2),census_bound_catb(:,1),'y')
plot(census_bound_cata(:,2),census_bound_cata(:,1),'g')
grid on;
axis square;
ylabel('Latitude')
xlabel('Longitude')
title({'Initialization Area for 3.5 GHz Simulation'})
filename1=strcat('initial_parameters1.png');
saveas(gcf,char(filename1))


end




















