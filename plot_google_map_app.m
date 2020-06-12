 function varargout = plot_google_map_app(app,varargin)
            persistent apiKey useTemp
            if isnumeric(apiKey)
                % first run, check if API key file exists
                if exist('api_key.mat','file')
                    load api_key
                else
                    apiKey = '';
                end
            end
            if isempty(useTemp)
                % first run, check if we have wrtie access to the temp folder
                try
                    tempfilename = tempname;
                    fid = fopen(tempfilename, 'w');
                    if fid > 0
                        fclose(fid);
                        useTemp = true;
                        delete(tempfilename);
                    else
                        % Don't have write access to temp folder or it doesn't exist, fallback to current dir
                        useTemp = false;
                    end
                catch
                    % in case tempname fails for some reason
                    useTemp = false;
                end
            end
            
            hold(app.UIAxes,'on');
            
            %%%%%%%%% Default parametrs
            %axHandle = gca; % Original
            axHandle=app.UIAxes;
            
            %set(axHandle, 'Layer','top'); %Original % Put axis on top of image, so it doesn't hide the axis lines and ticks
            axHandle.Layer = 'top';
            
            height = 640;
            width = 640;
            scale = 2;
            resize = 1;
            maptype = 'roadmap';
            alphaData = 1;
            autoRefresh = 1;
            figureResizeUpdate = 1;
            autoAxis = 1;
            showLabels = 1;
            language = '';
            markeridx = 1;
            markerlist = {};
            style = '';
            
            %%%%%%Figure is made after this point
            
            % Handle input arguments
            if nargin >= 2
                for idx = 1:2:length(varargin)
                    switch lower(varargin{idx})
                        case 'axis'
                            axHandle = varargin{idx+1};
                        case 'height'
                            height = varargin{idx+1};
                        case 'width'
                            width = varargin{idx+1};
                        case 'scale'
                            scale = round(varargin{idx+1});
                            if scale < 1 || scale > 2
                                error('Scale must be 1 or 2');
                            end
                        case 'resize'
                            resize = varargin{idx+1};
                        case 'maptype'
                            maptype = varargin{idx+1};
                        case 'alpha'
                            alphaData = varargin{idx+1};
                        case 'refresh'
                            autoRefresh = varargin{idx+1};
                        case 'showlabels'
                            showLabels = varargin{idx+1};
                        case 'figureresizeupdate'
                            figureResizeUpdate = varargin{idx+1};
                        case 'language'
                            language = varargin{idx+1};
                        case 'marker'
                            markerlist{markeridx} = varargin{idx+1};
                            markeridx = markeridx + 1;
                        case 'autoaxis'
                            autoAxis = varargin{idx+1};
                        case 'apikey'
                            apiKey = varargin{idx+1}; % set new key
                            %%%%%%%% save key to file
                            %funcFile = which('plot_google_map_app.m');
                            %pth = fileparts(funcFile);
                            %keyFile = fullfile(pth,'api_key.mat');
                            %save(keyFile,'apiKey')
                        case 'style'
                            style = varargin{idx+1};
                        otherwise
                            error(['Unrecognized variable: ' varargin{idx}])
                    end
                end
            end
            if height > 640
                height = 640;
            end
            if width > 640
                width = 640;
            end
            
            % Store paramters in axis handle (for auto refresh callbacks)
            ud = get(axHandle, 'UserData');
            if isempty(ud)
                % explicitly set as struct to avoid warnings
                ud = struct;
            end
            ud.gmap_params = varargin;
            set(axHandle, 'UserData', ud);
            
            curAxis = axis(axHandle);
            if max(abs(curAxis)) > 500 || curAxis(3) > 90 || curAxis(4) < -90
                warning('Axis limits are not reasonable for WGS1984, ignoring. Please make sure your plotted data in WGS1984 coordinates,')
                return;
            end
            
            % Enforce Latitude constraints of EPSG:900913
            if curAxis(3) < -85
                curAxis(3) = -85;
            end
            if curAxis(4) > 85
                curAxis(4) = 85;
            end
            % Enforce longitude constrains
            if curAxis(1) < -180
                curAxis(1) = -180;
            end
            if curAxis(1) > 180
                curAxis(1) = 0;
            end
            if curAxis(2) > 180
                curAxis(2) = 180;
            end
            if curAxis(2) < -180
                curAxis(2) = 0;
            end
            
            if isequal(curAxis,[0 1 0 1]) % probably an empty figure
                % display world map
                curAxis = [-200 200 -85 85];
                axis(curAxis)
            end
            
            
            if autoAxis
                % adjust current axis limit to avoid strectched maps
                [xExtent,yExtent] = latLonToMeters(app,curAxis(3:4), curAxis(1:2) );
                xExtent = diff(xExtent); % just the size of the span
                yExtent = diff(yExtent);
                % get axes aspect ratio
                drawnow
                org_units = get(axHandle,'Units');
                set(axHandle,'Units','Pixels')
                ax_position = get(axHandle,'position');
                set(axHandle,'Units',org_units)
                aspect_ratio = ax_position(4) / ax_position(3);
                
                if xExtent*aspect_ratio > yExtent
                    centerX = mean(curAxis(1:2));
                    centerY = mean(curAxis(3:4));
                    spanX = (curAxis(2)-curAxis(1))/2;
                    spanY = (curAxis(4)-curAxis(3))/2;
                    
                    % enlarge the Y extent
                    spanY = spanY*xExtent*aspect_ratio/yExtent; % new span
                    if spanY > 85
                        spanX = spanX * 85 / spanY;
                        spanY = spanY * 85 / spanY;
                    end
                    curAxis(1) = centerX-spanX;
                    curAxis(2) = centerX+spanX;
                    curAxis(3) = centerY-spanY;
                    curAxis(4) = centerY+spanY;
                elseif yExtent > xExtent*aspect_ratio
                    
                    centerX = mean(curAxis(1:2));
                    centerY = mean(curAxis(3:4));
                    spanX = (curAxis(2)-curAxis(1))/2;
                    spanY = (curAxis(4)-curAxis(3))/2;
                    % enlarge the X extent
                    spanX = spanX*yExtent/(xExtent*aspect_ratio); % new span
                    if spanX > 180
                        spanY = spanY * 180 / spanX;
                        spanX = spanX * 180 / spanX;
                    end
                    
                    curAxis(1) = centerX-spanX;
                    curAxis(2) = centerX+spanX;
                    curAxis(3) = centerY-spanY;
                    curAxis(4) = centerY+spanY;
                end            
                % Enforce Latitude constraints of EPSG:900913
                if curAxis(3) < -85
                    curAxis(3:4) = curAxis(3:4) + (-85 - curAxis(3));
                end
                if curAxis(4) > 85
                    curAxis(3:4) = curAxis(3:4) + (85 - curAxis(4));
                end
                axis(axHandle, curAxis); % update axis as quickly as possible, before downloading new image
                drawnow
            end
            
            % Delete previous map from plot (if exists)
            if nargout <= 1 % only if in plotting mode
                curChildren = get(axHandle,'children');
                map_objs = findobj(curChildren,'tag','gmap');
                bd_callback = [];
                for idx = 1:length(map_objs)
                    if ~isempty(get(map_objs(idx),'ButtonDownFcn'))
                        % copy callback properties from current map
                        bd_callback = get(map_objs(idx),'ButtonDownFcn');
                    end
                end
                delete(map_objs)
            end
            
            % Calculate zoom level for current axis limits
            [xExtent,yExtent] = latLonToMeters(app,curAxis(3:4), curAxis(1:2) );
            minResX = diff(xExtent) / width;
            minResY = diff(yExtent) / height;
            minRes = max([minResX minResY]);
            tileSize = 256;
            initialResolution = 2 * pi * 6378137 / tileSize; % 156543.03392804062 for tileSize 256 pixels
            zoomlevel = floor(log2(initialResolution/minRes));
            
            % Enforce valid zoom levels
            if zoomlevel < 0
                zoomlevel = 0;
            end
            if zoomlevel > 19
                zoomlevel = 19;
            end
            
            % Calculate center coordinate in WGS1984
            lat = (curAxis(3)+curAxis(4))/2;
            lon = (curAxis(1)+curAxis(2))/2;
            
            % Construct query URL
            preamble = 'http://maps.googleapis.com/maps/api/staticmap';
            location = ['?center=' num2str(lat,10) ',' num2str(lon,10)];
            zoomStr = ['&zoom=' num2str(zoomlevel)];
            sizeStr = ['&scale=' num2str(scale) '&size=' num2str(width) 'x' num2str(height)];
            maptypeStr = ['&maptype=' maptype ];
            if ~isempty(apiKey)
                keyStr = ['&key=' apiKey];
            else
                keyStr = '';
            end
            markers = '&markers=';
            for idx = 1:length(markerlist)
                if idx < length(markerlist)
                    markers = [markers markerlist{idx} '%7C'];
                else
                    markers = [markers markerlist{idx}];
                end
            end
            
            if showLabels == 0
                if ~isempty(style)
                    style = [style '&style='];
                end
                style = [style 'feature:all|element:labels|visibility:off'];
            end
            
            if ~isempty(language)
                languageStr = ['&language=' language];
            else
                languageStr = '';
            end
            
            if ismember(maptype,{'satellite','hybrid'})
                filename = 'tmp.jpg';
                format = '&format=jpg';
                convertNeeded = 0;
            else
                filename = 'tmp.png';
                format = '&format=png';
                convertNeeded = 1;
            end
            sensor = '&sensor=false';
            
            if ~isempty(style)
                styleStr = ['&style=' style];
            else
                styleStr = '';
            end
            
            url = [preamble location zoomStr sizeStr maptypeStr format markers languageStr sensor keyStr styleStr];
            
            % Get the image
            if useTemp
                filepath = fullfile(tempdir, filename);
            else
                filepath = filename;
            end
            
            try
                urlwrite(url,filepath);
            catch % error downloading map
                warning(['Unable to download map form Google Servers.\n' ...
                    'Matlab error was: %s\n\n' ...
                    'Possible reasons: missing write permissions, no network connection, quota exceeded, or some other error.\n' ...
                    'Consider using an API key if quota problems persist.\n\n' ...
                    'To debug, try pasting the following URL in your browser, which may result in a more informative error:\n%s'], lasterr, url);
                varargout{1} = [];
                varargout{2} = [];
                varargout{3} = [];
                return
            end
            
            %%%%%%Figure is made after this point
            
            [M, Mcolor] = imread(filepath);
            Mcolor = uint8(Mcolor * 255);
            %M = cast(M,'double');
            delete(filepath); % delete temp file
            width = size(M,2);
            height = size(M,1);
            
            % We now want to convert the image from a colormap image with an uneven
            % mesh grid, into an RGB truecolor image with a uniform grid.
            % This would enable displaying it with IMAGE, instead of PCOLOR.
            % Advantages are:
            % 1) faster rendering
            % 2) makes it possible to display together with other colormap annotations (PCOLOR, SCATTER etc.)
            
            % Convert image from colormap type to RGB truecolor (if PNG is used)
            if convertNeeded
                imag = zeros(height,width,3, 'uint8');
                for idx = 1:3
                    cur_map = Mcolor(:,idx);
                    imag(:,:,idx) = reshape(cur_map(M+1),height,width);
                end
            else
                imag = M;
            end
            % Resize if needed
            if resize ~= 1
                imag = imresize(imag, resize, 'bilinear');
            end
            
            % Calculate a meshgrid of pixel coordinates in EPSG:900913
            width = size(imag,2);
            height = size(imag,1);
            centerPixelY = round(height/2);
            centerPixelX = round(width/2);
            [centerX,centerY] = latLonToMeters(app,lat, lon ); % center coordinates in EPSG:900913
            curResolution = initialResolution / 2^zoomlevel / scale / resize; % meters/pixel (EPSG:900913)
            xVec = centerX + ((1:width)-centerPixelX) * curResolution; % x vector
            yVec = centerY + ((height:-1:1)-centerPixelY) * curResolution; % y vector
            [xMesh,yMesh] = meshgrid(xVec,yVec); % construct meshgrid
            
            % convert meshgrid to WGS1984
            [lonMesh,latMesh] = metersToLatLon(app,xMesh,yMesh);
            
            % Next, project the data into a uniform WGS1984 grid
            uniHeight = round(height*resize);
            uniWidth = round(width*resize);
            latVect = linspace(latMesh(1,1),latMesh(end,1),uniHeight);
            lonVect = linspace(lonMesh(1,1),lonMesh(1,end),uniWidth);
            [uniLonMesh,uniLatMesh] = meshgrid(lonVect,latVect);
            uniImag = zeros(uniHeight,uniWidth,3);
            
            % Fast Interpolation to uniform grid
            uniImag =  myTurboInterp2(app,lonMesh,latMesh,imag,uniLonMesh,uniLatMesh);
            
            if nargout <= 1 % plot map
                %%%%% display image
                %hold(axHandle, 'on'); %Original
                hold(app.UIAxes,'on');
                
                %cax = caxis;
                cax = app.UIAxes.CLim;
                
                h = image(lonVect,latVect,uniImag, 'Parent', axHandle);
                %caxis(cax); %%%Original % Preserve caxis that is sometimes changed by the call to image()
                app.UIAxes.CLim=cax;% Preserve caxis that is sometimes changed by the call to image()
                
                %set(axHandle,'YDir','Normal') %%%Original
                app.UIAxes.YDir = 'Normal';
                
                set(h,'tag','gmap')
                set(h,'AlphaData',alphaData)
                
                % add a dummy image to allow pan/zoom out to x2 of the image extent
                h_tmp = image(lonVect([1 end]),latVect([1 end]),zeros(2),'Visible','off', 'Parent', axHandle, 'CDataMapping', 'scaled');
                set(h_tmp,'tag','gmap')
                
                %%uistack(h,'bottom') % move map to bottom (so it doesn't hide previously drawn annotations)
                
                axis(axHandle, curAxis) % restore original zoom
                if nargout == 1
                    varargout{1} = h;
                end
                
                % if auto-refresh mode - override zoom callback to allow autumatic
                % refresh of map upon zoom actions.
                figHandle = axHandle;
                while ~strcmpi(get(figHandle, 'Type'), 'figure')
                    % Recursively search for parent figure in case axes are in a panel
                    figHandle = get(figHandle, 'Parent');
                end
                
%                 zoomHandle = zoom(axHandle);
%                 panHandle = pan(figHandle); % This isn't ideal, doesn't work for contained axis
%                 if autoRefresh
%                     set(zoomHandle,'ActionPostCallback',@update_google_map);
%                     set(panHandle, 'ActionPostCallback', @update_google_map);
%                 else % disable zoom override
%                     set(zoomHandle,'ActionPostCallback',[]);
%                     set(panHandle, 'ActionPostCallback',[]);
%                 end
                
                %%%% set callback for figure resize function, to update extents if figure is streched.
%                 if figureResizeUpdate &&isempty(get(figHandle, 'ResizeFcn'))
%                     % set only if not already set by someone else
%                     set(figHandle, 'ResizeFcn', @update_google_map_fig);
%                 end
                
                %%%% set callback properties
                set(h,'ButtonDownFcn',bd_callback);
            else % don't plot, only return map
                varargout{1} = lonVect;
                varargout{2} = latVect;
                varargout{3} = uniImag;
            end

            
            % Coordinate transformation functions
            
            function [lon,lat] = metersToLatLon(app,x,y)
                % Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum
                originShift = 2 * pi * 6378137 / 2.0; % 20037508.342789244
                lon = (x ./ originShift) * 180;
                lat = (y ./ originShift) * 180;
                lat = 180 / pi * (2 * atan( exp( lat * pi / 180)) - pi / 2);
            end
            
            function [x,y] = latLonToMeters(app,lat, lon )
                % Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913"
                originShift = 2 * pi * 6378137 / 2.0; % 20037508.342789244
                x = lon * originShift / 180;
                y = log(tan((90 + lat) * pi / 360 )) / (pi / 180);
                y = y * originShift / 180;
            end
            
            
            function ZI = myTurboInterp2(app,X,Y,Z,XI,YI)
                % An extremely fast nearest neighbour 2D interpolation, assuming both input
                % and output grids consist only of squares, meaning:
                % - uniform X for each column
                % - uniform Y for each row
                XI = XI(1,:);
                X = X(1,:);
                YI = YI(:,1);
                Y = Y(:,1);
                
                xiPos = nan*ones(size(XI));
                xLen = length(X);
                yiPos = nan*ones(size(YI));
                yLen = length(Y);
                % find x conversion
                xPos = 1;
                for idx = 1:length(xiPos)
                    if XI(idx) >= X(1) && XI(idx) <= X(end)
                        while xPos < xLen && X(xPos+1)<XI(idx)
                            xPos = xPos + 1;
                        end
                        diffs = abs(X(xPos:xPos+1)-XI(idx));
                        if diffs(1) < diffs(2)
                            xiPos(idx) = xPos;
                        else
                            xiPos(idx) = xPos + 1;
                        end
                    end
                end
                % find y conversion
                yPos = 1;
                for idx = 1:length(yiPos)
                    if YI(idx) <= Y(1) && YI(idx) >= Y(end)
                        while yPos < yLen && Y(yPos+1)>YI(idx)
                            yPos = yPos + 1;
                        end
                        diffs = abs(Y(yPos:yPos+1)-YI(idx));
                        if diffs(1) < diffs(2)
                            yiPos(idx) = yPos;
                        else
                            yiPos(idx) = yPos + 1;
                        end
                    end
                end
                ZI = Z(yiPos,xiPos,:);
            end
            
            
            function update_google_map(app,obj,evd)
                % callback function for auto-refresh
                drawnow;
                try
                    axHandle = evd.Axes;
                catch ex
                    % Event doesn't contain the correct axes. Panic!
                    axHandle = gca;
                end
                ud = get(axHandle, 'UserData');
                if isfield(ud, 'gmap_params')
                    params = ud.gmap_params;
                    plot_google_map_app(params{:});
                end
            end
            
            
            function update_google_map_fig(app,obj,evd)
                % callback function for auto-refresh
                drawnow;
                axes_objs = findobj(get(gcf,'children'),'type','axes');
                for idx = 1:length(axes_objs)
                    if ~isempty(findobj(get(axes_objs(idx),'children'),'tag','gmap'));
                        ud = get(axes_objs(idx), 'UserData');
                        if isfield(ud, 'gmap_params')
                            params = ud.gmap_params;
                        else
                            params = {};
                        end
                        
                        % Add axes to inputs if needed
                        if ~sum(strcmpi(params, 'Axis'))
                            params = [params, {'Axis', axes_objs(idx)}];
                        end
                        plot_google_map_app(params{:});
                    end
                end
            end
         end