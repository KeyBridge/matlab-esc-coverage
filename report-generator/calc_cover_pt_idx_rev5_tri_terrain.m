function [temp_coverage_pt_idx]=calc_cover_pt_idx_rev5_tri_terrain(app,rel50,confidence,radar_height,temp_50pts,temp_esc_info,FreqMHz,path_loss_threshold,single_uni_esc_data,TerHandler,TerDirectory)

if all(isnan(temp_50pts))==1
    temp_coverage_pt_idx=NaN(1);
else
    
    %%%%%%%%%%%%%Now we cycle through each ESC and calculate the path loss for the specific DPA
    %%%%%%%%%%%%%%%%ITMP2P
    %tic;
    if isdeployed==1
        NET.addAssembly(which('SEADLib.dll'));
    else
        NET.addAssembly(fullfile('C:\USGS','SEADLib.dll'));
        %NET.addAssembly('C:\USGS\SEADLib.dll');
    end
    
    itmp = ITMAcs.ITMP2P;
    Dielectric=81.0;
    Conduct=5.0;
    Refrac=350.0;
    RadClim=int32(7); % 1 Equatorial, 2 Continental Subtorpical, 3 Maritime Tropical, 4 Desert, % 5 Continental Temperate, 6 Maritime Over Land, 7 Maritime Over Sea
    RelPct=rel50/100; %0.5;
    ConfPct=confidence/100;
    TxHtm=radar_height;
    Tpol=1;
    [num_pts,~]=size(temp_50pts);
    
    RxLat=temp_esc_info(1);
    RxLon=temp_esc_info(2);
    RxHtm=temp_esc_info(3);
    
    %%%%Preallocate
    dBloss=NaN(num_pts,1);
    for pt_idx=1:1:num_pts  %%%%For Now, send in one point at a time
        disp_sub_progress(app,strcat(num2str(pt_idx/num_pts*100),'%'))
        TxLat=temp_50pts(pt_idx,1);
        TxLon=temp_50pts(pt_idx,2);
        
        %%%%%%%First Try 1 arcsend, then 3 arc second
        tf_error=0;
        
        if isdeployed==1
            TerDirectory = 'P:\NED1\float';
        else
            TerDirectory = 'C:\NED1\float';
            %TerDirectory = 'P:\NED1\float';
        end
        TerHandler = int32(2); % 0 for GLOBE, 1 for USGS 3 sec, 2 for USGS 1 sec
        temp_dBloss=NaN(1);
        try
            [temp_dBloss]=itmp.ITMp2pAryRels(TxHtm,RxHtm,Refrac,Conduct,Dielectric,FreqMHz,RadClim,Tpol,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
        catch
            tf_error=1;
            label='1 Arc Second Error'
            %                     figure;
            %                     hold on;
            %                     plot(us_cont(:,2),us_cont(:,1),'-k')
            %                     plot(TxLon,TxLat,'sb')
            %                     plot(RxLon,RxLat,'or')
            %                     horzcat(TxLat,TxLon)
            %                     horzcat(RxLat,RxLon)
            %                     horzcat(Refrac,RadClim)
            %                     temp_dist=deg2km(distance(TxLat,TxLon,RxLat,RxLon))
            %pause
            %                     close all;
        end
        
        %%%%%%%%%Try 3 arc second database
        if tf_error==1 || double(temp_dBloss)<0
            tf_error=0;
            TerDirectory='C:\USGS\';
            TerHandler = int32(1); % 0 for GLOBE, 1 for USGS 3 sec, 2 for USGS 1 sec
            try
                [temp_dBloss]=itmp.ITMp2pAryRels(TxHtm,RxHtm,Refrac,Conduct,Dielectric,FreqMHz,RadClim,Tpol,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
            catch
                tf_error=1;
                label='3 Arc Second Error'
                %                         figure;
                %                         hold on;
                %                         plot(us_cont(:,2),us_cont(:,1),'-k')
                %                         plot(TxLon,TxLat,'sb')
                %                         plot(RxLon,RxLat,'or')
                %                         horzcat(TxLat,TxLon)
                %                         horzcat(RxLat,RxLon)
                %                         horzcat(Refrac,RadClim)
                %                         temp_dist=deg2km(distance(TxLat,TxLon,RxLat,RxLon))
                %pause
                %                         close all;
            end
            
            %%%%%%%%Try Globe Database
            if tf_error==1 || double(temp_dBloss)<0
                TerDirectory='C:\USGS\';
                TerHandler = int32(0); % 0 for GLOBE, 1 for USGS 3 sec, 2 for USGS 1 sec
                try
                    [temp_dBloss]=itmp.ITMp2pAryRels(TxHtm,RxHtm,Refrac,Conduct,Dielectric,FreqMHz,RadClim,Tpol,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
                catch
                    label='GLOBE Error'
                    %pause
                    %                             figure;
                    %                             hold on;
                    %                             plot(us_cont(:,2),us_cont(:,1),'-k')
                    %                             plot(TxLon,TxLat,'sb')
                    %                             plot(RxLon,RxLat,'or')
                    %                             horzcat(TxLat,TxLon)
                    %                             horzcat(RxLat,RxLon)
                    %                             horzcat(Refrac,RadClim)
                    %                             temp_dist=deg2km(distance(TxLat,TxLon,RxLat,RxLon))
                    %                             pause
                    %                             close all;
                end
            end
        end
        
        
        % %                 try
        % %                     %tic;
        % %                     [temp_dBloss]=itmp.ITMp2pAryRels(TxHtm,RxHtm,Refrac,Conduct,Dielectric,FreqMHz,RadClim,Tpol,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
        % %                     %toc;
        % %                 catch
        % %                     %%%%%%%%Error
        % %                     disp_progress(app,'ITM Error: Sim Paused')
        % %
        % %
        % %                     pause;
        % %                 end
        
        if double(temp_dBloss)<0
            %%%%%%%%Error
            double(temp_dBloss)
            disp_progress(app,'ITM Error: Less than 0dB Path Loss')
            pause;
        end
        dBloss(pt_idx,:)=double(temp_dBloss);
    end
    %toc;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%Add Antenna Beamwidth and Azimuth Direction
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    full_temp_ant_gain360=single_uni_esc_data{4};
    temp_ant_gain360=full_temp_ant_gain360(:,2);
    
    %%%%%%%Cable Loss
    temp_esc_cable_loss=temp_esc_info(7);
    % %             disp_progress(app,strcat('Cable Loss:',num2str(temp_esc_cable_loss),'dB'))
    % %             pause;
    
    %%%%%%%%%%%%%%%%%%%%%%%%50th
    %%%%%%Now Calculate the Azimuth from the ESC to the filter_pts50/95 and determine the antenna gain
    temp_calc_azi50=round(azimuth(temp_esc_info(1),temp_esc_info(2),temp_50pts(:,1),temp_50pts(:,2)));
    temp_050idx=temp_calc_azi50==0;
    temp_calc_azi50(temp_050idx)=360;
    calc_ant_gain50=temp_ant_gain360(temp_calc_azi50);
    
    %%%%%Calculate Total Loss
    total_dB_loss50=dBloss+temp_esc_cable_loss-calc_ant_gain50;
    
    %%%%%%%%Find where the dBloss is less than path_loss_threshold
    temp_coverage_pt_idx=find(total_dB_loss50<path_loss_threshold);
end

end