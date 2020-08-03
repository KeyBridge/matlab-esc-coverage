function [filter_pts95,filter_pts50]=parfor_gridpoints(app,pt_idx,uni_dpa_index,step_size,cell_all_dpa,cell_75km_dpa)

        tic;
        %%%%%%Check for grid points
        file_name_50pts=strcat('filter_pts50_',num2str(uni_dpa_index(pt_idx)),'_',num2str(step_size),'km.mat');
        file_name_95pts=strcat('filter_pts95_',num2str(uni_dpa_index(pt_idx)),'_',num2str(step_size),'km.mat');
        [var_exist_50pts]=persistent_var_exist(app,file_name_50pts);
        [var_exist_95pts]=persistent_var_exist(app,file_name_95pts);
        if var_exist_50pts==2 && var_exist_95pts==2%%%%%Load
            retry_load=1;
            while(retry_load==1)
                try
                    load(file_name_50pts,'filter_pts50')
                    load(file_name_95pts,'filter_pts95')
                    retry_load=0;
                catch
                    retry_load=1;
                    pause(0.1)
                end
            end
        else
            disp_progress(app,'Generating Grid Points')
            dpa_bound=cell_all_dpa{uni_dpa_index(pt_idx),2};
            %%%Need to generate points along the DPA edge based upon the spacing
            [filter_pts50]=grid_points_app(app,dpa_bound,step_size);
            
            %%%%%%%%We need a filter_pts95 for the 75km DPA Bound <--95%
            dpa75_bound=cell_75km_dpa{uni_dpa_index(pt_idx)};
            [filter_pts95]=grid_points_app(app,dpa75_bound,step_size);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%Cut the filter_pts50 inside the dpa75_bound, mainly to reduce computational time
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [x27,y27]=size(dpa75_bound);
            if x27>1
                %%%%bufferm the dpa75_bound by 1km for the cut below
                pgon75=polyshape(dpa75_bound(:,2),dpa75_bound(:,1));
                buff_pgon75=polybuffer(pgon75,0.001);
                %idx50_pts = find(isinterior(buff_pgon75,filter_pts50(:,2),filter_pts50(:,1))==0)

                %%%%%%%%Use loop because of memory issues with a large
                %%%%%%%%amount of points and isinterior.
                [x91,y91]=size(filter_pts50);
                idx50_pts=NaN(x91,1);
                for k=1:1:x91
                    temp_idx50_pts=find(isinterior(buff_pgon75,filter_pts50(k,2),filter_pts50(k,1))==0);
                    if ~isempty(temp_idx50_pts)==1
                        idx50_pts(k)=k;
                    end
                end
                
                idx50_pts=idx50_pts(~isnan(idx50_pts));
                filter_pts50=filter_pts50(idx50_pts,:);
                
                if isempty(filter_pts50)==1
                    [x10,~]=size(dpa_bound);
                    dist_steps=NaN(x10-1,1);
                    for j=1:1:x10-1
                        dist_steps(j)=deg2km(distance(dpa_bound(j,1),dpa_bound(j,2),dpa_bound(j+1,1),dpa_bound(j+1,2)));
                    end
                    seg_dist=nansum(dist_steps);
                    line_steps=ceil(seg_dist/(step_size))+1;
                    dpa_edge_pt=curvspace_app(app,dpa_bound,line_steps);
                    filter_pts50=dpa_edge_pt;
                end
                
                if isempty(filter_pts95)==1
                    [x10,~]=size(dpa75_bound);
                    dist_steps=NaN(x10-1,1);
                    for j=1:1:x10-1
                        dist_steps(j)=deg2km(distance(dpa75_bound(j,1),dpa75_bound(j,2),dpa75_bound(j+1,1),dpa75_bound(j+1,2)));
                    end
                    seg_dist=nansum(dist_steps);
                    line_steps=ceil(seg_dist/(step_size))+1;
                    dpa_edge_pt=curvspace_app(app,dpa75_bound,line_steps);
                    filter_pts95=dpa_edge_pt;
                end
                
                close all;
                figure;
                hold on;
                plot(dpa_bound(:,2),dpa_bound(:,1),'-k')
                plot(filter_pts50(:,2),filter_pts50(:,1),'or')
                plot(filter_pts95(:,2),filter_pts95(:,1),'sb')
                grid on;
                pause(0.1)
            end
            retry_save=1;
            while(retry_save==1)
                try
                    save(file_name_50pts,'filter_pts50')
                    save(file_name_95pts,'filter_pts95')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
        end
        toc;
end