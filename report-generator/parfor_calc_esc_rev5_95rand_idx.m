function parfor_calc_esc_rev5_95rand_idx(app,temp_esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,TerHandler,TerDirectory,array_rand_esc_idx)


%%%%%%%%Break the 50 and 95 into separate functions


%%%%%%This is 95
            esc_idx=array_rand_esc_idx(temp_esc_idx);
            single_uni_esc_data=uni_esc_name_dpa(esc_idx,:);
            temp_cover_dpa_idx=single_uni_esc_data{3};
            temp_esc_info=single_uni_esc_data{2};
            x16=length(temp_cover_dpa_idx);
            if isempty(temp_cover_dpa_idx)==1
                %%%%Nothing
            else
                for j=1:1:x16
                    temp_dpa_idx=temp_cover_dpa_idx(j);
                    temp_pt_idx=find(uni_dpa_index==temp_dpa_idx);
                    
                    %%%%%%%Check for calculation, else, calc_cover_pt_idx
                    file_name_temp_coverage_95pts=strcat('temp_coverage95_',single_uni_esc_data{1},'_DPA',num2str(temp_cover_dpa_idx(j)),'_',num2str(step_size),'km.mat');
                    [var_exist_95_coverage]=persistent_var_exist(app,file_name_temp_coverage_95pts);
                    
                    if var_exist_95_coverage==2 %%%%%Load
                        %%%%%%%%No Load
                    else
                        tic;
                        %%%%%%%Calculate the Path Loss
                        temp_95pts=cell_95_dpa_pts{temp_pt_idx};
                        rel95=reliability(2);
                        
                        [temp_coverage95]=calc_cover_pt_idx_rev5_tri_terrain(app,rel95,confidence,radar_height,temp_95pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data,TerHandler,TerDirectory);
                      
                        retry_save=1;
                        while(retry_save==1)
                            try
                                save(file_name_temp_coverage_95pts,'temp_coverage95')
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        toc;
                    end
                end
            end
end