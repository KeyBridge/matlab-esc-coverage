clear;
clc;
close all;
format shortg
app=NaN(1);
base_folder='Z:\MATLAB\3.5GHz\DPA Coverage Analysis\Keybridge Matlab Code';
cd(base_folder);




write_report=1%0
tf_custom_ant=1%0
parallel_flag=1%0%1%1%0%1; %This way we can see the progress bar.
workers=4%0;
tf_load=1%0%1 %%%%%If 1, then it loads the coverage plots
industry_label='KEY';


TerHandler=int32(1)
if TerHandler==2
    TerDirectory = 'C:\NED1\float';
elseif TerHandler==1
    TerDirectory = 'C:\USGS\';
end



temp_sub_files=dir;
x3=length(temp_sub_files);
temp_filenames=cell(x3,1);
for i=1:1:x3
    temp_filenames{i}=temp_sub_files(i).name;
end
idx_location=find(contains(temp_filenames,strcat('ESC_Location_Inputs')))
idx_logic=find(contains(temp_filenames,strcat('ESC_Combo_Logic_Inputs')))
idx_pattern=find(contains(temp_filenames,strcat('ESC_Antenna_Gain_Pattern')))

if isempty(idx_location)==1 || length(idx_location)>1
    disp_progress(app,strcat('File Error Location Inputs [Pause]'))
    temp_filenames(idx_location)
    pause;
end

if isempty(idx_logic)==1 || length(idx_logic)>1
    disp_progress(app,strcat('File Error Logic Inputs [Pause]'))
    temp_filenames(idx_logic)
    pause;
end

if isempty(idx_pattern)==1 || length(idx_pattern)>1
    disp_progress(app,strcat('File Error Antenna Pattern Input [Pause]'))
    pause;
end


filename1=temp_filenames{idx_location}
filename2=temp_filenames{idx_logic}
filename3=temp_filenames{idx_pattern}



step_size=100%50%100; %km
esc_analysis_rev7_parfor_rand_app(app,step_size,filename1,filename2,filename3,parallel_flag,write_report,tf_custom_ant,tf_load,industry_label,TerHandler,TerDirectory,workers)
disp_progress(app,strcat('SIM DONE'))


