function [temp_cell_coverage50_pt_idx,temp_cell_coverage95_pt_idx]=parfor_calc_esc_rev4_terrain(app,esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_50_dpa_pts,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,tf_load,TerHandler,TerDirectory)

            single_uni_esc_data=uni_esc_name_dpa(esc_idx,:);
            temp_cover_dpa_idx=single_uni_esc_data{3};
            temp_esc_info=single_uni_esc_data{2};
            x16=length(temp_cover_dpa_idx);
            if isempty(temp_cover_dpa_idx)==1
                %%%%Nothing
                temp_cell_coverage50_pt_idx=cell(1);
                temp_cell_coverage95_pt_idx=cell(1);
            else
                temp_cell_coverage50_pt_idx=cell(x16,1);
                temp_cell_coverage95_pt_idx=cell(x16,1);
                for j=1:1:x16
                    temp_dpa_idx=temp_cover_dpa_idx(j);
                    temp_pt_idx=find(uni_dpa_index==temp_dpa_idx);
                    
                    %%%%%%%Check for calculation, else, calc_cover_pt_idx
                    file_name_temp_coverage_50pts=strcat('temp_coverage50_',single_uni_esc_data{1},'_DPA',num2str(temp_cover_dpa_idx(j)),'_',num2str(step_size),'km.mat');
                    file_name_temp_coverage_95pts=strcat('temp_coverage95_',single_uni_esc_data{1},'_DPA',num2str(temp_cover_dpa_idx(j)),'_',num2str(step_size),'km.mat');
                    [var_exist_50_coverage]=persistent_var_exist(app,file_name_temp_coverage_50pts);
                    [var_exist_95_coverage]=persistent_var_exist(app,file_name_temp_coverage_95pts);
                    
                    if var_exist_50_coverage==2 && var_exist_95_coverage==2%%%%%Load
                        if tf_load==1
                            retry_load=1;
                            while(retry_load==1)
                                try
                                    load(file_name_temp_coverage_50pts,'temp_coverage50')
                                    load(file_name_temp_coverage_95pts,'temp_coverage95')
                                    retry_load=0;
                                catch
                                    retry_load=1;
                                    pause(0.1)
                                end
                            end
                        else
                            temp_coverage50=NaN(1,1);
                            temp_coverage95=NaN(1,1);
                        end
                    else
                        tic;
                        %%%%%%%Calculate the Path Loss
                        temp_50pts=cell_50_dpa_pts{temp_pt_idx};
                        temp_95pts=cell_95_dpa_pts{temp_pt_idx};
                        rel50=reliability(1);
                        rel95=reliability(2);
                        

                        %%%%%%%%%%%%%Now we cycle through each ESC and calculate the path loss, and the point idx that are covered for the specific DPA
                        %temp_coverage50=calc_cover_pt_idx_rev2_ant(app,rel50,confidence,radar_height,temp_50pts,temp_esc_info,FreqMHz,min_ant_loss,path_loss_threshold,custom_ant_gain,single_uni_esc_data);
                        %temp_coverage95=calc_cover_pt_idx_rev2_ant(app,rel95,confidence,radar_height,temp_95pts,temp_esc_info,FreqMHz,min_ant_loss,path_loss_threshold,custom_ant_gain,single_uni_esc_data);
                        
                        %[temp_coverage50]=calc_cover_pt_idx_rev3_multi_ant(app,rel50,confidence,radar_height,temp_50pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data);
                        %[temp_coverage95]=calc_cover_pt_idx_rev3_multi_ant(app,rel95,confidence,radar_height,temp_95pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data);
                                      
                        %[temp_coverage50]=calc_cover_pt_idx_rev4_terrain(app,rel50,confidence,radar_height,temp_50pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data,TerHandler,TerDirectory);
                        %[temp_coverage95]=calc_cover_pt_idx_rev4_terrain(app,rel95,confidence,radar_height,temp_95pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data,TerHandler,TerDirectory);
                        
                        [temp_coverage50]=calc_cover_pt_idx_rev5_tri_terrain(app,rel50,confidence,radar_height,temp_50pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data,TerHandler,TerDirectory);
                        [temp_coverage95]=calc_cover_pt_idx_rev5_tri_terrain(app,rel95,confidence,radar_height,temp_95pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data,TerHandler,TerDirectory);
                      
                        retry_save=1;
                        while(retry_save==1)
                            try
                                save(file_name_temp_coverage_50pts,'temp_coverage50')
                                save(file_name_temp_coverage_95pts,'temp_coverage95')
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        toc;
                    end
                    temp_cell_coverage50_pt_idx{j}=temp_coverage50;
                    temp_cell_coverage95_pt_idx{j}=temp_coverage95;
                end
            end
end