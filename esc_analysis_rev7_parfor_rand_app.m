function esc_analysis_rev7_parfor_rand_app(app,step_size,filename1,filename2,filename3,parallel_flag,write_report,tf_custom_ant,tf_load,industry_label,TerHandler,TerDirectory,workers)

top_start_clock=clock;
% % % 210 dB path loss threshold shall be used
% % % Radar EIRP (121 dBm/MHz) – ESC detection threshold (-89 dBm/MHz)
% % % ITM 50% Confidence and 95% Reliability shall be used to calculate path loss thresholds to locations within 75 km from the shore
% % % Provides margin for asymmetrical propagation paths between CBSDs, DPA analysis points and ESC locations
% % % ITM 50% Confidence and 50% Reliability can be used to calculate path loss thresholds for the remainder of the DPA area
% % % Conditional probability shall not be used
% % % ESC detection independence can not be assumed - propagation conditions are routinely similar over large distances
% % % Coverage shall be determined as the superset of all DPA ESCs – as long as any one ESC meets the detection criteria for a given DPA location, the location is covered

%load('us_cont.mat','us_cont')
reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
confidence=50;
reliability=[50,95];
FreqMHz=3600;
min_ant_loss=20;

%%%%%%Radar Parameters
radar_height=50; %%%%%Meters
path_loss_threshold=210; %%%dB: Radar EIRP (121 dBm/MHz) – ESC detection threshold (-89 dBm/MHz)
% % % ITM 50% Confidence and 95% Reliability shall be used to calculate path loss thresholds to locations within 75 km from the shore
% % % ITM 50% Confidence and 50% Reliability can be used to calculate path loss thresholds for the remainder of the DPA area


%%%%%%Persistent Load
retry_load=1;
while(retry_load==1)
    try
        load('cell_expand_all_dpa.mat','cell_expand_all_dpa')  %%%%%%Name, Full DPA, 75km DPA
        clear temp_data;
        temp_data=cell_expand_all_dpa;
        clear cell_expand_all_dpa;
        cell_expand_all_dpa=temp_data;
        
        cell_75km_dpa=cell_expand_all_dpa(:,3);
        cell_all_dpa=cell_expand_all_dpa(:,1:2);
        
        %%%%%%%Eliminate the San Diego 50% points
        cell_all_dpa{46,2}=NaN(1,2);
        
        %%%%%%%Eliminate the Alameda 50% points
        cell_all_dpa{47,2}=NaN(1,2);
        
        %%%%%%%Eliminate the Long Beach 50% points
        cell_all_dpa{48,2}=NaN(1,2);
        
        %%%%%Eliminate the Bremerton 50% Points
        cell_all_dpa{49,2}=NaN(1,2);
        
        
        %%%%%Eliminate the Norfolk 50% Points
        cell_all_dpa{27,2}=NaN(1,2);
        
        %%%%%Eliminate the Mayport 50% Points
        cell_all_dpa{28,2}=NaN(1,2);
        
        %%%%%Eliminate the PascagoulaPort 50% Points
        cell_all_dpa{29,2}=NaN(1,2);
        
        %%%%%Eliminate the Webster 50% Points
        cell_all_dpa{30,2}=NaN(1,2);
        
        %%%%%Eliminate the Pensacola 50% Points
        cell_all_dpa{31,2}=NaN(1,2);
        
        
% % % %         cell_all_dpa
% % % %         'NaN the 50% Points for the Ports'
        
        
% %         load('cell_75km_dpa.mat','cell_75km_dpa')
% %         clear temp_data;
% %         temp_data=cell_75km_dpa;
% %         clear cell_75km_dpa;
% %         cell_75km_dpa=temp_data;
% %         
% %         load('cell_all_dpa.mat','cell_all_dpa')
% %         clear temp_data;
% %         temp_data=cell_all_dpa;
% %         clear cell_all_dpa;
% %         cell_all_dpa=temp_data;
        
        pause(0.1)
        retry_load=0;
    catch
        retry_load=1;
        pause(1)
    end
end


%%%%%%%Read in the ESC xls file for the inputs %%%%DPA_East_02
%%%%%%%%For the app, the user will load in the xlsx file
tic;
[num,txt,raw]=xlsread(filename1);
% % % % save('txt.mat','txt')
% % % % save('raw.mat','raw')
% % % load('txt.mat','txt')
% % % load('raw.mat','raw')
toc;
header_varname=txt(1,:);

%%%%%%%%%If the table gets new columns, find the header names assign them dynamically
idx_lat=find(contains(header_varname,'Latitude'));
idx_lon=find(contains(header_varname,'Longitude'));
idx_ant_height=find(contains(header_varname,'ESC Antenna Height'));
idx_ant_azi=find(contains(header_varname,'ESC Antenna Azimuth'));
idx_ant_bw=find(contains(header_varname,'Antenna Beamwidth'));
idx_ant_gain=find(contains(header_varname,'Antenna Gain'));
idx_site_name=find(contains(header_varname,'Site Name'));
idx_cable_loss=find(contains(header_varname,'Cable Loss'));
idx_ant_name=find(contains(header_varname,'Antenna Name'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
temp_lat=cell2mat(raw(2:end,idx_lat));
temp_lat=temp_lat(~isnan(temp_lat));
temp_lon=cell2mat(raw(2:end,idx_lon));
temp_lon=temp_lon(~isnan(temp_lon));
temp_ant_height=cell2mat(raw(2:end,idx_ant_height));
temp_ant_height=temp_ant_height(~isnan(temp_ant_height));
temp_ant_azi=cell2mat(raw(2:end,idx_ant_azi));
temp_ant_azi=temp_ant_azi(~isnan(temp_ant_azi));
temp_ant_bw=cell2mat(raw(2:end,idx_ant_bw));
temp_ant_bw=temp_ant_bw(~isnan(temp_ant_bw));
temp_ant_gain_dB=cell2mat(raw(2:end,idx_ant_gain));
temp_ant_gain_dB=temp_ant_gain_dB(~isnan(temp_ant_gain_dB));
temp_site_name=raw(2:(length(temp_lat)+1),idx_site_name);
temp_site_name=cellfun(@num2str,temp_site_name,'un',0); %%%Just make sure it is a string
temp_cable_loss=cell2mat(raw(2:end,idx_cable_loss));
temp_cable_loss=temp_cable_loss(~isnan(temp_cable_loss));
temp_ant_name=raw(2:(length(temp_lat)+1),idx_ant_name);
temp_ant_name=cellfun(@num2str,temp_ant_name,'un',0); %%%Just make sure it is a string

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+

%%%%%%%%%%%%%%%%Check to see if you have the adequate info for each ESC.
%%%%%%%Check the size of the inputs, needs to be the same length
tf_esc_check1=isequal(length(temp_lat),length(temp_lon),length(temp_ant_height),length(temp_ant_azi),length(temp_ant_bw),length(temp_ant_gain_dB),length(temp_site_name),length(temp_cable_loss));

%%%%%Also check to see if there are any empty slots, which will be NaNs
tf_esc_check2=any(isnan(vertcat(temp_lat,temp_lon,temp_ant_height,temp_ant_azi,temp_ant_bw,temp_ant_gain_dB,temp_cable_loss)))==0;

temp_ant_bw

if tf_esc_check1==0 || tf_esc_check2==0
    tf_esc_check1
    tf_esc_check2
    disp_progress(app,strcat('Incomplete ESC Location Inputs'))
    pause;
end


if tf_custom_ant==1
    tic;
    [num3,txt3,raw3]=xlsread(filename3);
    toc;
    header3_varname=txt3(1,:);
    idx_degree=find(contains(header3_varname,'Degrees'));
    temp_degree=cell2mat(raw3(2:end,idx_degree));
    temp_degree=temp_degree(~isnan(temp_degree));
    idx_antennas=2:1:length(header3_varname);
    ant_names_header=header3_varname(idx_antennas);
    x7=length(idx_antennas);
    cell_custom_ant=cell(x7,1);
    for i=1:1:x7
        temp_ant_gain_array=cell2mat(raw3(2:end,idx_antennas(i)));
        temp_ant_gain_array=temp_ant_gain_array(~isnan(temp_ant_gain_array));
        ant_gain_dual_rows=horzcat(temp_degree,temp_ant_gain_array);
        idx_zero=find(ant_gain_dual_rows(:,1)==0);
        cell_custom_ant{i}=circshift(ant_gain_dual_rows,360-(idx_zero-1));
    end
else
    custom_ant_gain=NaN(1);
    cell_custom_ant=NaN(1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Import the ESC Combinatorial Logic
tic;
[num2,txt2,raw2]=xlsread(filename2);
toc;
header2_varname=txt2(1,:);
idx_dpa=find(contains(header2_varname,'DPA Covered'));
temp_dpa=raw2(2:end,idx_dpa);
logic_row=cell(length(temp_dpa),1);
for i=1:1:length(temp_dpa)
    temp_row=raw2(i+1,:);
    temp_row(cellfun(@(temp_row) any(isnan(temp_row)),temp_row))=[];
    logic_row{i}=cellfun(@num2str,temp_row,'un',0); %%%Just make sure it is a string
end
logic_row=logic_row(~cellfun(@isempty, logic_row)); %%%%Remove empty rows



%%%%%%%%%%%%Find the ESC that cover East 1,
%%%%%%%%%%%% and find the coverage for each specific ESC for the 95/50% and see
uni_esc_name_dpa=cell(length(temp_site_name),4); %%%%Site Name, ESC info (lat/lon/etc.), idx of DPA, Custom Antenna Pattern Or Normal Pattern
uni_esc_name_dpa(:,1)=temp_site_name;
for i=1:1:length(temp_site_name)
    uni_esc_name_dpa{i,2}=horzcat(temp_lat(i),temp_lon(i),temp_ant_height(i),temp_ant_azi(i),temp_ant_bw(i),temp_ant_gain_dB(i),temp_cable_loss(i));
    
    
    if tf_custom_ant==1
        %%%%%Find the Antenna Gain and Cable Loss to Pass On
        idx_custom_ant=find(contains(ant_names_header,temp_ant_name{i}));
        custom_ant_gain=cell_custom_ant{idx_custom_ant};
        uni_esc_name_dpa{i,4}=circshift(custom_ant_gain,temp_ant_azi(i)-1);
    else
        %%%%%%%%Calculate ESC Antenna Gain
        
        if temp_ant_bw(i)==360
            temp_array_ant_gain=ones(1,length(0:1:180))*temp_ant_gain_dB(i);
        else
            temp_array_ant_gain=(-12*((0:1:180)/temp_ant_bw(i)).^2)+temp_ant_gain_dB(i);
        end
        idx_below_min=find(temp_array_ant_gain<-1*min_ant_loss); %%%%%%Max Antenna Loss 25dBi
        temp_array_ant_gain(idx_below_min)=-1*min_ant_loss;
        temp_ant_gain360=horzcat(temp_array_ant_gain,fliplr(temp_array_ant_gain(2:end-1)));

% % %         close all;
% % %         figure;
% % %         hold on;
% % %         plot(temp_ant_gain360,'-ob')
% % %         grid on;
% % %         pause(1)
        uni_esc_name_dpa{i,4}=circshift(temp_ant_gain360,temp_ant_azi(i)-1);  %%%%%%%%%0 azimuth off-axis should be the 360 index
    end
    
    single_site_name=temp_site_name{i};
    for j=1:1:length(logic_row)
        single_temp_logic_row=logic_row{j};
        temp_find_idx=find(strcmpi(single_temp_logic_row,single_site_name)==1);
        if ~isempty(temp_find_idx)==1
            %%%%%%Find the DPA idx
            temp_dpa_idx=find(strcmpi(cell_all_dpa(:,1),single_temp_logic_row{1}));
            
            %%%%%%%%Add the dpa idx to an array
            temp_idx_array=uni_esc_name_dpa{i,3};
            temp_idx_array=unique(vertcat(temp_idx_array,temp_dpa_idx));
            uni_esc_name_dpa{i,3}=temp_idx_array;
        end
    end
end

%%%%%%%%%%%%%%%%%%Generate 50 and 95 points for each DPA
uni_dpa_index=unique(cell2mat(uni_esc_name_dpa(:,3)));

if length(uni_dpa_index)==1
    dpa_labels=cell_all_dpa{uni_dpa_index,1};
else
    full_uni_dpa_names=cell_all_dpa(uni_dpa_index,1);
    
    %%%%%Find the East/West DPAs
    idx_east_dpa=find(contains(full_uni_dpa_names,'East'));
    idx_west_dpa=find(contains(full_uni_dpa_names,'West'));
    
    full_temp_idx=[1:1:length(full_uni_dpa_names)]';
    idx_other_dpa=setxor(union(idx_east_dpa,idx_west_dpa),full_temp_idx);
    
    
    if ~isempty(idx_east_dpa)==1
        % %         %%%%%Find the East DPAs numbers
        % %         east_dpa_num=NaN(length(idx_east_dpa),1);
        % %         for i=1:1:length(idx_east_dpa)
        % %             temp_split= strsplit(full_uni_dpa_names{i},' ');
        % %             east_dpa_num(i)=str2num(temp_split{2});
        % %
        % %         end
        % %         east_dpa_num
        east_label=strcat('East',num2str(length(idx_east_dpa)));
    else
        east_label=strcat('East',num2str(0));
    end
    
    if ~isempty(idx_west_dpa)==1
        west_label=strcat('West',num2str(length(idx_west_dpa)));
    else
        west_label=strcat('West',num2str(0));
    end
    
    if ~isempty(idx_other_dpa)==1
        other_label=strcat('Other',num2str(length(idx_other_dpa)));
    else
        other_label=strcat('Other',num2str(0));
    end
    
    dpa_labels=strcat('Multi-',east_label,'-',west_label,'-',other_label);
end

date_string=datestr(datetime('today'))

%WordFileName=strcat(industry_label,'_',dpa_labels,'_ESC_Report_',num2str(step_size),'km',date_string,'.doc');
WordFileName=strcat(industry_label,'_',dpa_labels,'_ESC_Report_',num2str(step_size),'km.doc');
%%%%%%%%%Need to Delete a previous report if it has the same name
tf_word = exist(WordFileName,'file');
if tf_word==2 && write_report==1
    %%%%%%%%Report Already Exists
elseif tf_word==0  %%%%%This will stop it from trying to calculate it if there is a report
    x15=length(uni_dpa_index);
    cell_50_dpa_pts=cell(x15,1);
    cell_95_dpa_pts=cell(x15,1);
    if parallel_flag==1
        disp_progress(app,strcat('Starting Parallel Workers . . . [This usually takes a little time]'))
        pause(0.1);
        [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
        disp_progress(app,strcat('Grid Points'))
        [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Grid Points: ',x15);    %%%%%%% Create ParFor Waitbar
        parfor pt_idx=1:1:x15
            [cell_95_dpa_pts{pt_idx},cell_50_dpa_pts{pt_idx}]=parfor_gridpoints(app,pt_idx,uni_dpa_index,step_size,cell_all_dpa,cell_75km_dpa);
            hWaitbarMsgQueue.send(0)
        end
        delete(hWaitbarMsgQueue);
        close(hWaitbar);
    else
        for pt_idx=1:1:x15
            [cell_95_dpa_pts{pt_idx},cell_50_dpa_pts{pt_idx}]=parfor_gridpoints(app,pt_idx,uni_dpa_index,step_size,cell_all_dpa,cell_75km_dpa);
        end
    end
    horzcat(cell_50_dpa_pts,cell_95_dpa_pts)
    uni_esc_name_dpa
    
    %%%%%%%%%%Now Calculate the esc coverage for each site for each dpa_idx
    [x13,y13]=size(uni_esc_name_dpa)
    cell_single_esc_coverage50=cell(x13,1);
    cell_single_esc_coverage95=cell(x13,1);
    tic;
       
    if parallel_flag==1
        %%%%%%%%%First save and then load in two functions.
        
        disp_progress(app,strcat('Starting Parallel Workers . . . [This usually takes a little time]'))
        pause(0.1);
        [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
        disp_progress(app,strcat('Parfor Calculating'))
                %%%%%%%This is not optimized for parallel calculations, we need to
        %%%%%%%make a wrapper that saves/calculates the 50 and 95 in parallel and then
        %%%%%%%loads then in at the end.
        array_rand_esc_idx=randsample(x13,x13,false);
        [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Calculating 50th: ',x13);    %%%%%%% Create ParFor Waitbar
        parfor temp_esc_idx=1:1:x13
            %%%%%[cell_single_esc_coverage50{esc_idx},cell_single_esc_coverage95{esc_idx}]=parfor_calc_esc_rev4_terrain(app,esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_50_dpa_pts,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,tf_load,TerHandler,TerDirectory);
            parfor_calc_esc_rev5_50rand_idx(app,temp_esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_50_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,TerHandler,TerDirectory,array_rand_esc_idx)
            hWaitbarMsgQueue.send(0)
        end
        delete(hWaitbarMsgQueue);
        close(hWaitbar);
        
        array_rand_esc_idx=randsample(x13,x13,false);
        [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Calculating 95th: ',x13);    %%%%%%% Create ParFor Waitbar
        parfor temp_esc_idx=1:1:x13
            %%%%%[cell_single_esc_coverage50{esc_idx},cell_single_esc_coverage95{esc_idx}]=parfor_calc_esc_rev4_terrain(app,esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_50_dpa_pts,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,tf_load,TerHandler,TerDirectory);
            parfor_calc_esc_rev5_95rand_idx(app,temp_esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,TerHandler,TerDirectory,array_rand_esc_idx)
            hWaitbarMsgQueue.send(0)
        end
        delete(hWaitbarMsgQueue);
        close(hWaitbar);
        
        %%%%%%Now Load
        [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Loading Data: ',x13);    %%%%%%% Create ParFor Waitbar
        parfor esc_idx=1:1:x13
            [cell_single_esc_coverage50{esc_idx},cell_single_esc_coverage95{esc_idx}]=parfor_calc_esc_rev4_terrain(app,esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_50_dpa_pts,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,tf_load,TerHandler,TerDirectory);
            hWaitbarMsgQueue.send(0)
        end
        delete(hWaitbarMsgQueue);
        close(hWaitbar);
        
    else
        %parfor_progress_time(app,x13);
        for esc_idx=1:1:x13
            [cell_single_esc_coverage50{esc_idx},cell_single_esc_coverage95{esc_idx}]=parfor_calc_esc_rev4_terrain(app,esc_idx,uni_esc_name_dpa,uni_dpa_index,cell_50_dpa_pts,cell_95_dpa_pts,reliability,confidence,radar_height,FreqMHz,path_loss_threshold,step_size,tf_load,TerHandler,TerDirectory);
            %parfor_progress_time(app);
        end
        %parfor_progress_time(app,0);
    end
    toc;
    
    
    %%%%%%%%Now union the point_idx for all ESC Combinations in a DPA for each logic_row
    x20=length(logic_row)
    cell_combo_50pt_idx=cell(x20,1);
    cell_combo_95pt_idx=cell(x20,1);
    array_coverage_calc=NaN(x20,2); %%%%% 95% and 50% DPA Coverage Percentage
    for logic_idx=1:1:x20
        temp_logic_row=logic_row{logic_idx};
        temp_dpa_name=temp_logic_row{1};
        temp_dpa_idx=find(strcmpi(cell_all_dpa(:,1),temp_dpa_name)); %%%%%%Find the DPA_IDX
        
        
        %%%%%Find the ESC names on the list
        temp_esc_names=temp_logic_row(2:end);
        [~,x22]=size(temp_esc_names);
        temp_combo_50idx=cell(x22,1);
        temp_combo_95idx=cell(x22,1);
        temp_array_esc_idx=NaN(x22,1);
        for k=1:1:x22
            temp_esc_row_idx=find(strcmpi(uni_esc_name_dpa(:,1),temp_esc_names{k})==1);
            
% % % %             uni_esc_name_dpa
            temp_esc_names{k}
            temp_esc_row_idx
            temp_array_esc_idx(k)=temp_esc_row_idx;
            temp_pt_group_idx=find(temp_dpa_idx==uni_esc_name_dpa{temp_esc_row_idx,3});
            
            first_temp_95cell=cell_single_esc_coverage95{temp_esc_row_idx,:};
            first_temp_50cell=cell_single_esc_coverage50{temp_esc_row_idx,:};
            
            temp_combo_95idx{k}=first_temp_95cell{temp_pt_group_idx};
            temp_combo_50idx{k}=first_temp_50cell{temp_pt_group_idx};
        end
        
        uni_95pt_idx=unique(cell2mat(temp_combo_95idx));
        uni_50pt_idx=unique(cell2mat(temp_combo_50idx));
        
        cell_combo_95pt_idx{logic_idx}=uni_95pt_idx;
        cell_combo_50pt_idx{logic_idx}=uni_50pt_idx;
        
        %%%%%%%Calculate Coverage
        temp_pt_idx=find(temp_dpa_idx==uni_dpa_index);
        temp_95pts=cell_95_dpa_pts{temp_pt_idx};
        temp_50pts=cell_50_dpa_pts{temp_pt_idx};
        
        [num95,y26]=size(temp_95pts);
        [num50,y25]=size(temp_50pts);
        
        if all(isnan(temp_50pts))==1
            array_coverage_calc(logic_idx,2)=NaN(1);
        else
            array_coverage_calc(logic_idx,2)=(length(uni_50pt_idx)./num50).*100;
        end
        array_coverage_calc(logic_idx,1)=(length(uni_95pt_idx)./num95).*100;
        
        if write_report==0 && tf_load==1
            disp_progress(app,strcat('Plotting Data . . .'))
            pause(0.1);
            
            %%%%%%%%%%Temp Plot for Now
            close all;
            figure;
            hold on;
            scatter(temp_50pts(uni_50pt_idx,2),temp_50pts(uni_50pt_idx,1),10,'g','filled')
            scatter(temp_95pts(uni_95pt_idx,2),temp_95pts(uni_95pt_idx,1),10,'g','filled')
            non_temp50_idx=setdiff(1:1:num50,uni_50pt_idx);
            non_temp95_idx=setdiff(1:1:num95,uni_95pt_idx);
            scatter(temp_50pts(non_temp50_idx,2),temp_50pts(non_temp50_idx,1),10,'r','filled')
            scatter(temp_95pts(non_temp95_idx,2),temp_95pts(non_temp95_idx,1),10,'r','filled')
            dpa_bound=cell_all_dpa{temp_dpa_idx,2};
            plot(dpa_bound(:,2),dpa_bound(:,1),'-k')
            dpa75_bound=cell_75km_dpa{temp_dpa_idx};
            dpa75_bound=vertcat(dpa75_bound,dpa75_bound(1,:));
            plot(dpa75_bound(:,2),dpa75_bound(:,1),'-k')
            for n=1:1:length(temp_array_esc_idx)
                single_uni_esc_data=uni_esc_name_dpa(temp_array_esc_idx(n),:);
                temp_esc_info=single_uni_esc_data{2};
                plot(temp_esc_info(:,2),temp_esc_info(:,1),'sb','LineWidth',2)
                if n==1
                    esc_labels=single_uni_esc_data{1};
                else
                    esc_labels=strcat(esc_labels,'-',single_uni_esc_data{1});
                end
            end
            %title({strcat(cell_all_dpa{temp_dpa_idx,1},' DPA: ',esc_labels),strcat('Covereage Percentage'),strcat('Reliability 95:',num2str(round(array_coverage_calc(logic_idx,1),1)),'%'),strcat('Reliability 50:',num2str(round(array_coverage_calc(logic_idx,2),1)),'%')})
            title({strcat(cell_all_dpa{temp_dpa_idx,1},' DPA: ',esc_labels),strcat('Covereage Percentage'),strcat('Reliability 95:',num2str(round(array_coverage_calc(logic_idx,1),5)),'%'),strcat('Reliability 50:',num2str(round(array_coverage_calc(logic_idx,2),5)),'%')},'Interpreter', 'none')
            xlabel('Longitude')
            ylabel('Latitude')
            plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
            grid on;
            filename3=strcat(num2str(step_size),'km_',cell_all_dpa{temp_dpa_idx,1},'_logic',num2str(logic_idx),'_',esc_labels,'.png');
            saveas(gcf,char(filename3))
        end
    end
    
    if write_report==1 && tf_load==1
        disp_progress(app,strcat('Writing the Report . . .'))
        pause(0.1);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Make a Word Report
        
        
        %%%%%%%%%Need to Delete a previous report if it has the same name
        tf_word = exist(WordFileName,'file');
        if tf_word==2 %%%%%%Delete the File
            %delete(WordFileName)
        else
            
            
            CurDir=pwd;
            FileSpec = fullfile(CurDir,WordFileName);
            [ActXWord,WordHandle]=StartWord_app(app,FileSpec);
            
            fprintf('Document will be saved in %s\n',FileSpec);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Section 1
            %%create header in word
            Style='Heading 1';
            TextString='Notice of DPA Submission';
            WordText_app(app,ActXWord,TextString,Style,[0,2]);%two enters after text
            
            Style='Normal';
            for i=1:1:length(uni_dpa_index)
                if i==length(uni_dpa_index)
                    TextString=strcat(cell_all_dpa{uni_dpa_index(i)});
                else
                    temp_cell=strcat(cell_all_dpa{uni_dpa_index(i)},',',{' '});
                    TextString=temp_cell{1};
                end
                
                %WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
                WordText_app(app,ActXWord,TextString,Style,[0,0]);%enter after text
            end
            
            Style='Normal';
            TextString='';
            WordText_app(app,ActXWord,TextString,Style,[0,1]);
            
            TextString=date_string;
            WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
            
            ActXWord.Selection.InsertBreak; %pagebreak
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%Section 2
            style='Heading 1';
            text='Table of Contents';
            WordText_app(app,ActXWord,text,style,[1,1]);%enter before and after text
            WordCreateTOC_app(app,ActXWord,1,3);
            ActXWord.Selection.InsertBreak; %pagebreak
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % %Section 3: Simulation Assumptions
            Style='Heading 1';
            TextString='Simulation Assumptions';
            WordText_app(app,ActXWord,TextString,Style,[0,2]);%two enters after text
            
            Style='Normal';
            TextString=strcat(num2str(path_loss_threshold),'dB used as the path loss threshold.');
            WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
            
            TextString=strcat('ITM 50% Confidence and 95% Reliability used to calculate path loss thresholds to locations within 75km from the shore.');
            WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
            
            TextString=strcat('ITM 50% Confidence and 50% Reliability used to calculate path loss thresholds for the remainder of the DPA area.');
            WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
            
            temp_cell=strcat('DPA grid spacing set to ',{' '},num2str(step_size),'km.');
            TextString=temp_cell{1};
            WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
            ActXWord.Selection.InsertBreak; %pagebreak
            
            
            %%%%%%%%%%%%%%Create a Section for the ESC Antenna if there is a custom antenna model
            
            if all(isnan(custom_ant_gain))==0
                %%%%%%Create a Page
                x7=length(idx_antennas);
                for i=1:1:x7
                    Style='Heading 1';
                    TextString=strcat('Antenna Model--',ant_names_header{i});
                    WordText_app(app,ActXWord,TextString,Style,[0,2]);%two enters after text
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    Style='Normal';
                    TextString='';
                    WordText_app(app,ActXWord,TextString,Style,[0,0]);
                    
                    close all;
                    hFig=figure;
                    hold on;
                    ant_gain_dual_rows=cell_custom_ant{i};
                    shift_ant_gain_dual_rows=circshift(ant_gain_dual_rows,180);
                    shift_ant_gain_dual_rows(:,1)=mod(shift_ant_gain_dual_rows(:,1)+180,360)-180;
                    plot(shift_ant_gain_dual_rows(:,1),shift_ant_gain_dual_rows(:,2),'-ob')
                    grid on;
                    title({strcat('Antenna Pattern--',ant_names_header{i})})
                    xlabel('Degrees')
                    ylabel('Gain (dB)')
                    axis([-180,180,min(ylim),max(ylim)])
                    
                    FigureIntoWord_app(app,ActXWord,hFig); %insert the figure
                    WordText_app(app,ActXWord,TextString,Style,[0,1]);%one enter after figure
                    ActXWord.Selection.InsertBreak; %pagebreak
                end
            end
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Create a Separate Section for Each DPA
            length(uni_dpa_index)
            for dpa_idx=1:1:length(uni_dpa_index)
                Style='Heading 1';
                temp_cell=strcat('DPA:',{' '},cell_all_dpa{uni_dpa_index(dpa_idx)});
                TextString=temp_cell{1};
                WordText_app(app,ActXWord,TextString,Style,[0,2]);%two enters after text
                
                Style='Heading 2';
                TextString='ESC Site Information';
                WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Style='Normal';
                TextString='';
                WordText_app(app,ActXWord,TextString,Style,[0,0]);
                
                %%%%%%%%%%Find all the ESC that cover the: uni_dpa_index(dpa_idx)
                [x31,~]=size(uni_esc_name_dpa);
                %x31=length(uni_esc_name_dpa)
                temp_esc_array=[];
                temp_cell_esc_name=cell(1,1);
                temp_cell_ant_name=cell(1,1);
                for k=1:1:x31
                    tf_search=find(uni_esc_name_dpa{k,3}==uni_dpa_index(dpa_idx));
                    if ~isempty(tf_search)==1
                        %%%%%Add this ESC to the array
                        temp_esc_array=vertcat(temp_esc_array,uni_esc_name_dpa{k,2});
                        temp_cell_esc_name=vertcat(temp_cell_esc_name,temp_site_name{k});
                        temp_cell_ant_name=vertcat(temp_cell_ant_name,temp_ant_name{k});
                    end
                end
                %%%%%%%%Remove Empty Cell
                idx_non_empty=find(~cellfun('isempty', temp_cell_esc_name));
                temp_cell_esc_name=temp_cell_esc_name(idx_non_empty);
                
                idx_non_empty2=find(~cellfun('isempty', temp_cell_ant_name));
                temp_cell_ant_name=temp_cell_ant_name(idx_non_empty2);
                
                %%%%%%%Header cell
                header_cell={'ESC Name','Latitude (DD)','Longitude (DD)','ESC Height (m)','Azimuth (deg)','Antenna Beam width (deg)','Antenna Gain (dBi)','Cable Loss (dB)','Antenna Name'};
                
                % %                 if all(isnan(custom_ant_gain))==0
                % %                     temp_esc_array(:,5:6)=NaN(1);
                % %                 end
                
                %%%%%%%Each num has to be a stirng
                [x30,y30]=size(temp_esc_array);
                esc_data_cell=cell(x30,y30+2);
                for i=1:1:x30
                    esc_data_cell(i,2:end-1)=strsplit(num2str(temp_esc_array(i,:)),' ');
                end
                esc_data_cell(:,1)=temp_cell_esc_name;
                esc_data_cell(:,end)=temp_cell_ant_name;
                
                DataCell=vertcat(header_cell,esc_data_cell);
                [NoRows,NoCols]=size(DataCell);
                %create table with data from DataCell
                WordCreateTable_app(app,ActXWord,NoRows,NoCols,DataCell,0);%enter before table
                
                TextString='';
                WordText_app(app,ActXWord,TextString,Style,[0,1]);%two enters after text
                
                
                %%%%%%%%%%%%Add a table of the Combination Logic and the Coverage Percentage
                Style='Heading 2';
                TextString='ESC Combinations-DPA Coverage';
                WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Style='Normal';
                TextString='';
                WordText_app(app,ActXWord,TextString,Style,[0,0]);
                
                %%%%%%%%%%%%%%Find all Logic Rows with the Name of the DPA
                x20=length(logic_row);
                temp_logic_cell=cell(x20,1);
                temp_coverage_cell=cell(x20,2);
                for logic_idx=1:1:x20
                    temp_logic_row=logic_row{logic_idx};
                    temp_dpa_name=temp_logic_row{1};
                    temp_dpa_idx=find(strcmpi(cell_all_dpa(uni_dpa_index(dpa_idx),1),temp_dpa_name)); %%%%%%Find the DPA_IDX
                    if ~isempty(temp_dpa_idx)==1
                        temp_logic_cell{logic_idx}=temp_logic_row;
                        temp_coverage_cell{logic_idx,1}=strcat(num2str(array_coverage_calc(logic_idx,1)),'%');
                        temp_coverage_cell{logic_idx,2}=strcat(num2str(array_coverage_calc(logic_idx,2)),'%');
                    end
                end
                %%%%Eliminate the Empty cells
                idx_non_empty_plot=find(~cellfun(@isempty,temp_logic_cell));
                temp_logic_cell=temp_logic_cell(idx_non_empty_plot);
                temp_coverage_cell=temp_coverage_cell(idx_non_empty_plot,:);
                
                %%%%%Expand it out
                %%%%Find maximum length of each element
                x32=length(temp_logic_cell);
                temp_max_length=0;
                for k=1:1:x32
                    temp_max_length=max([temp_max_length,length(temp_logic_cell{k})]);
                end
                
                %%%%Fill in cells with empty cells
                expand_temp_logic_cell=temp_logic_cell;
                for k=1:1:x32
                    temp_cell_len=length(temp_logic_cell{k});
                    if temp_cell_len<temp_max_length
                        temp_add_cell=temp_max_length-temp_cell_len;
                        temp_space_cells=cell(1,temp_add_cell);
                        temp_space_cells(:)={' '};
                        expand_temp_logic_cell{k}=horzcat(temp_logic_cell{k},temp_space_cells);
                    end
                end
                temp_coverage_cell

                %%%%Unpack
                expand2_temp_logic_cell=horzcat(vertcat(expand_temp_logic_cell{:}),temp_coverage_cell);
                [x35,y35]=size(expand2_temp_logic_cell);
                
                %%%%%%%Header cell
                header_cell=cell(1,y35);
                header_cell{1}='DPA';
                header_cell(2:end-2)={'ESC'};
                header_cell(end-1)={'Coverage: 95%'};
                header_cell(end)={'Coverage: 50%'};
                DataCell=vertcat(header_cell,expand2_temp_logic_cell);
                [NoRows,NoCols]=size(DataCell);
                %%%%create table with data from DataCell
                WordCreateTable_app(app,ActXWord,NoRows,NoCols,DataCell,0);%enter before table
                TextString='';
                WordText_app(app,ActXWord,TextString,Style,[0,1]);%two enters after text
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Coverage Plot
                Style='Heading 2';
                TextString='ESC-DPA Coverage Map(s)';
                WordText_app(app,ActXWord,TextString,Style,[0,1]);%enter after text
                Style='Normal';
                TextString='';
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                temp_95pts=cell_95_dpa_pts{dpa_idx};
                temp_50pts=cell_50_dpa_pts{dpa_idx};
                [num95,y26]=size(temp_95pts);
                [num50,y25]=size(temp_50pts);
                x37=length(idx_non_empty_plot);
                for temp_idx=1:1:x37
                    logic_idx=idx_non_empty_plot(temp_idx);
                    temp_logic_row=logic_row{logic_idx};
                    
                    %%%%%%Find the ESC in this row
                    %%%%%Find the ESC names on the list
                    temp_esc_names=temp_logic_row(2:end);
                    [~,x22]=size(temp_esc_names);
                    temp_array_esc_idx=NaN(x22,1);
                    for k=1:1:x22
                        temp_esc_row_idx=find(strcmpi(uni_esc_name_dpa(:,1),temp_esc_names{k})==1);
                        temp_array_esc_idx(k)=temp_esc_row_idx;
                    end
                    
                    uni_95pt_idx=cell_combo_95pt_idx{logic_idx};
                    uni_50pt_idx=cell_combo_50pt_idx{logic_idx};
                    
                    %%%%%%%%%%Plot
                    close all;
                    hFig=figure;
                    hold on;
                    if all(isnan(temp_50pts))==0
                        scatter(temp_50pts(uni_50pt_idx,2),temp_50pts(uni_50pt_idx,1),5,'g','filled')
                    end
                    scatter(temp_95pts(uni_95pt_idx,2),temp_95pts(uni_95pt_idx,1),5,'g','filled')
                    non_temp50_idx=setdiff(1:1:num50,uni_50pt_idx);
                    non_temp95_idx=setdiff(1:1:num95,uni_95pt_idx);
                    scatter(temp_50pts(non_temp50_idx,2),temp_50pts(non_temp50_idx,1),5,'r','filled')
                    scatter(temp_95pts(non_temp95_idx,2),temp_95pts(non_temp95_idx,1),5,'r','filled')
                    dpa_bound=cell_all_dpa{uni_dpa_index(dpa_idx),2};
                    plot(dpa_bound(:,2),dpa_bound(:,1),'-k')
                    dpa75_bound=cell_75km_dpa{uni_dpa_index(dpa_idx)};
                    dpa75_bound=vertcat(dpa75_bound,dpa75_bound(1,:));
                    plot(dpa75_bound(:,2),dpa75_bound(:,1),'-k')
                    for n=1:1:length(temp_array_esc_idx)
                        single_uni_esc_data=uni_esc_name_dpa(temp_array_esc_idx(n),:);
                        temp_esc_info=single_uni_esc_data{2};
                        plot(temp_esc_info(:,2),temp_esc_info(:,1),'sb','LineWidth',2)
                        if n==1
                            esc_labels=single_uni_esc_data{1};
                        else
                            esc_labels=strcat(esc_labels,'-',single_uni_esc_data{1});
                        end
                    end
                    temp_logic_row=logic_row{logic_idx};
                    temp_dpa_name=temp_logic_row{1};
                    temp_dpa_idx=find(strcmpi(cell_all_dpa(:,1),temp_dpa_name)); %%%%%%Find the DPA_IDX
                    %title({strcat(cell_all_dpa{uni_dpa_index(dpa_idx),1},' DPA: ',esc_labels),strcat('Covereage Percentage'),strcat('Reliability 95:',num2str(round(array_coverage_calc(logic_idx,1),1)),'%'),strcat('Reliability 50:',num2str(round(array_coverage_calc(logic_idx,2),1)),'%')},'Interpreter', 'none')
                    title({strcat(cell_all_dpa{temp_dpa_idx,1},' DPA: ',esc_labels),strcat('Covereage Percentage'),strcat('Reliability 95:',num2str(round(array_coverage_calc(logic_idx,1),5)),'%'),strcat('Reliability 50:',num2str(round(array_coverage_calc(logic_idx,2),5)),'%')},'Interpreter', 'none')

                    xlabel('Longitude')
                    ylabel('Latitude')
                    %plot_google_map_app(app,'maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                    grid on;
                    
                    FigureIntoWord_app(app,ActXWord,hFig); %insert the figure
                    WordText_app(app,ActXWord,TextString,Style,[0,1]);%one enter after figure
                end
                
                %dpa_idx~=length(uni_dpa_index)
                
                if dpa_idx~=length(uni_dpa_index)
                    ActXWord.Selection.InsertBreak; %pagebreak
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%add pagenumbers (0=not on first page)
            WordPageNumbers_app(app,ActXWord,'wdAlignPageNumberRight');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%Last thing is to replace the Table of Contents so all headings are included.
            %%%%%%%%%Selection.GoTo What:=wdGoToField, Which:=wdGoToPrevious, Count:=1, Name:= "TOC"
            WordGoTo_app(app,ActXWord,7,3,1,'TOC',1);%%last 1 to delete the object
            WordCreateTOC_app(app,ActXWord,1,3);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            CloseWord_app(app,ActXWord,WordHandle,FileSpec);   %%%%%%%%%Save and Close Word
            close all;
        end
    end
    close all;
end

end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end



end