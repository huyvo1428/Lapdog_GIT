%% ORBIT Plot orbit trajectory
% |orbit(object, time, origin, frame)| plots the trajectory of _object_
% (string) during the time interval specified by _time_ (1x2 cell array of
% strings or 2x1 array of double precision values) w.r.t. _origin_ (string)
% in the reference frame specified by _frame_ (string). The plot is in 3D.
% Also plotted are the radial distance and latitude of _object_ w.r.t.
% _origin_ in the given _frame_, as well as the solar aspect angle (SAA).
%
% If time contains more than two epochs, these are used as sample times
% rather than start/stop times.
%   
% Available frames are any frames natively recognized by SPICE. Or 'IAU',
% specifying the body-fixed (rotating) frame cenetered on origin. Or
% 'Terminal', specifying a frame centered on origin with the x-axis
% pointing towards the Sun (the z-axis is the orthogonal projection of
% the IAU z-axis w.r.t the x-axis).
%   
% If time contains more than one epoch, a 2D plot of object's radial
% distance and latitude is produced, in addition to the 3D trajectory plot.
% (OBS! The latitude values depend on the frame of reference chosen!)
%
% If time consists of floating point number(s), these are interpreted as 
% representing the number of TDB seconds past the J2000 epoch, i.e.
% Ephemeris Time (ET). Alternatively, epochs may be supplied in the form
% of a cell array containing string(s) in any format recognized by SPICE
% as epochs. (E.g. the ISOC calendar format: YYYY-MM-DDThh:mm:ss.sss)
%
% |orbit(object, time, origin, frame, h)|, where |h| is a four-element
% vector of axes handles, draws the 3D, latitude/longitude, radial distance
% and SAA  plots in the axes specified by h(1), h(2) and h(3), respectively.
% If any of the elements of |h| are zero, the corresponding plots are
% suppressed.
%
% |orbit(object, time, origin, frame, file_name)|, where _file_name_ is a
% string, writes out the illuminations conditions to the text file
% _file_name_.
%
% |orbit(object, time, origin, frame, CData)|, where _CData_ is a numerical
% vector of the same length as _time_, colorcodes _object_'s trajectory by
% the values given in _CData_.
%
% |orbit(object, time, origin, frame, inData)|, where _inData_ is a struct
% with the same fields as _output_ (see below), plots orbital data in
% _inData_, without re-calculating any orbital data.
%
% |orbit(object, time, origin, frame, metakernel)|, where _metakernel_ is a
% struct with fields including _name_ and _folder_, as e.g. produced by
% the MATLAB routine |dir| on a string file path, makes use of the SPICE
% metakernel file in the given location, instead of loading kernel files
% from default locations.
%
% |output = orbit(object, time, origin, frame)| If an output argument is
% supplied, _output_ is given in the form of a struct varibale with the 
% following fields (Not complete list anymore! See section Output in the
% code below for further details.):
%   epoch: an Nx1 column vector of sample time epochs, in Ephemeris Time
%       (ET) format 
%   radial_distance: an Nx1 column vector of _object_ radial distances (in
%       km)
%   latitude: an Nx1 column vector of _object_ latitudes (in degrees,
%       w.r.t. _origin_ z-axis)
%   longitude: an Nx1 column vector of _object_ longitudes (in degrees,
%       w.r.t. _origin_ x-axis in _origin_ x-y plane) 
%   SAA: an Nx1 column vector of solar aspect angles (w.r.t the _object_
%       z-axis)
%   SEA: an Nx1 column vector of solar elevation angles (w.r.t the _object_
%       x-axis)
%   CAA: an Nx1 column vector of comet aspect angles (w.r.t the _object_
%       z-axis) [given only if _origin_ = 'CHURYUMOV-GERASIMENKO']
%   CEA: an Nx1 column vector of comet elevation angles (w.r.t the _object_
%       x-axis) [given only if _origin_ = 'CHURYUMOV-GERASIMENKO']
%   LAP1_ill_lims: a 1x2 row vector of limiting illumination angles of 
%       probe 1
%   LAP2_ill_lims: a 1x3 row vector of limiting illumination angles of
%       probe 2

function [varargout] = orbit_v2(object, time, origin, frame, varargin)
%% Set up paths and SPICE kernel files (DEPRACATED!)
% PATHS() gives paths to SPICE kernels directory and sets up MICE paths.
% lap.paths();

% %% Load SPICE kernel files
% % Check for metakernel file given as input:
% if nargin > 4
%     i_input_kernel = find(cellfun(@(x) isstruct(x) && any(cellfun(@(y) ...
%         strcmpi(y, 'name'), fieldnames(x), 'uni', true)) && any(cellfun(@(y) ...
%         strcmpi(y, 'folder'), fieldnames(x), 'uni', true)), varargin, 'uni', true));
%     in_kernel = ~isempty(i_input_kernel);
% else
%     in_kernel = false;
% end
% %%%
% % Load metakernel:
% if in_kernel
%     metakernel_path = [varargin{i_input_kernel}.folder '/' varargin{i_input_kernel}.name];
%     [loaded, kernelFolder, kernelFile] = lap.load_spice_kernels(metakernel_path);
% else
%     [loaded, kernelFolder, kernelFile] = lap.load_spice_kernels;
% end

%% Read input
% Check for input data:
in_data = nargin > 4 && any(cellfun(@(x) isstruct(x) && any(cellfun(@(y) ...
    strcmpi(y, 'epoch'), fieldnames(x), 'uni', true)), varargin));

%%%
% Get name of reference frame:
if (strcmpi(frame, 'IAU') || strcmpi(frame, 'Terminal'))
    ref = [frame '_' origin];
elseif (strcmpi(frame, 'CSO') || strcmpi(frame, 'CSEQ'))
    origin_id = cspice_bods2c(origin);
    if origin_id > 2e6  % Asteroids
        %%%
        % Asteroid frames require catalog number in front of body name:
        ref = [sprintf('%i', mod(origin_id, 1e6)) '/' origin '_' frame];
    else
        ref = [origin '_' frame];
    end
else
    ref = frame;
end
%%%
% Check for aux_data (see plotting section below):
aux_data = nargin > 4 && any(cellfun(@(x) isfloat(x), varargin)) && ...
    ~all(cell2mat(cellfun(@(x) all(ishandle(x)), varargin, 'uni', false)));

% If time is NOT floating point number(s), convert from string
% representation of epoch(s) to Ephemeris Time (ET):
if (isfloat(time))
    t = time;
else
    t = cspice_str2et(time);
end

%%%
% If precisely two input epochs are supplied, create equidistant sample
% times in between. Otherwise, use given epochs as sample times:
if (length(t) == 2)
%     dt = (t(2)-t(1))/10000;
    dt = 32;
    et = t(1):dt:t(2);
    if (dt > 60)
        warning('Time step larger than 1 minute. Accuracy may be inadequate.');
    end
else
    if (size(t, 1) > 1)
        et = t';
    else
        et = t;
    end
end

if (~in_data)
    %% Get SPICE orbit data
    % Check if parallel run possible:
    %isOnWorker = ~isempty(getCurrentTask());
     isOnWorker = true;

    %%%
    % Compute orbit states:
    if ~isOnWorker
        et_dist = distributed(et);
        spmd
            et_local = getLocalPart(et_dist);
            [local_loaded, local_kernelFolder, local_kernelFile] = lap.load_spice_kernels([kernelFolder '/' kernelFile]);
            state_dist = cspice_spkezr(object, et_local, ref, 'LT+S', origin);
        end
        state = cat(2, state_dist{:});
    else
        state = cspice_spkezr(object, et, ref, 'LT+S', origin);
    end

    %%%
    % Compute radial distance, latitude and longitude:
    [az, el, radial_distance] = cart2sph(state(1,:), state(2,:), state(3,:));
    longitude = rad2deg(az);
    latitude = rad2deg(el);
    

    %%%
    % Find direction of the sun:
    if ~isOnWorker
        spmd
            sun_dist = cspice_spkpos('Sun', et_local, ref, 'LT+S', object);
        end
        sun = cat(2, sun_dist{:});
    else
        sun = cspice_spkpos('Sun', et, ref, 'LT+S', object);
    end
    %%%
    % Compute sun distance, latitude and longitude:
    [sun_az, sun_el, sun_distance] = cart2sph(sun(1,:), sun(2,:), sun(3,:));
    sun_n = sun./repmat(sun_distance, 3, 1); % normalization

    %%%
    % Compute solar zenith angle:
    pos_n = state(1:3,:)./repmat(radial_distance, 3, 1);
    sza = acosd(dot(pos_n, sun_n))';

    %%%
    % Compute origin zero-longitude local time (~spin phase):
    % spin_phase = acosd(dot(repmat([1 0 0]', 1, size(sun_n, 2)), sun_n));
    % y_phase = dot(repmat([0 1 0]', 1, size(sun_n, 2)), sun_n);
    % lower_semicircle = (y_phase < 0);
    % spin_phase(lower_semicircle) = 360 - spin_phase(lower_semicircle);
    sun_lon = rad2deg(sun_az);
    sun_lat = rad2deg(sun_el);

    %% Get SPICE S/C orientation
    % Get object NAIF ID code:
    id = cspice_bodn2c(object);
    id_origin = cspice_bodn2c(origin);

    %%%
    % Make sure object id is negative number (may not be automatically
    % fulfilled for non-S/C bodies):
    id = -sign(id)*id;

    %%%
    % Convert to corresponding structure id:
    id_str = id*1000;

    %%%
    % Convert epochs to (continuous) spacecraft (object) clock counts:
    et_s = cspice_sce2c(id, et);
    
    %%%
    % Compute S/C attitude in the form of the rotation matrix(ces) that 
    % transform components of a vector expressed in the frame specified by 
    % 'ref' to components expressed in the frame tied to the spacecraft:
    if ~isOnWorker
        et_s = distributed(et_s);
        spmd
            %%%
            % Get change of basis transformation matrix:
            et_s_local = getLocalPart(et_s);
            [cmat, ~, found] = cspice_ckgp(id_str, et_s_local, 0, ref);
            %%%
            % Set not found values to NaN:
            cmat(:,:,~found) = NaN;
        end
        cmat = cat(3, cmat{:});
    else
        [cmat, ~, found] = cspice_ckgp(id_str, et_s, 0, ref);
    end
        
    %%%
    % Compute the inverse of the change of basis transformatation matrix (the 
    % COLUMNS of which are the the basis vectors of the object frame expressed in
    % the given 'base frame'):
    [~, ~, num] = size(cmat);
    basis = zeros(size(cmat));
    for i = 1:num
        %%%
        % The transformation matrix between two ortho-normal bases on the same
        % vector space is orthogonal, hence cmat^-1 = cmat^T, which is faster:
        basis(:,:,i) = cmat(:,:,i)';
    end

    %%%
    % Normalization:
    basis_n = basis;

    %%%
    % Find direction of the sun in S/C frame:
    if ~isOnWorker
        spmd
            sun_sc = NaN(3, length(et_local));
            if (any(found))
                sun_sc(:, found) = cspice_spkpos('Sun', et_local(found), 'ROS_SPACECRAFT', 'LT+S', object);
            end
        end
        sun_sc = cat(2, sun_sc{:});
    else
        sun_sc(:, found) = cspice_spkpos('Sun', et(found), 'ROS_SPACECRAFT', 'LT+S', object);
    end
    %%%
    % Transform to spherical coordinates about y-axis (i.e. x,y,z -> z,x,y):
    [sun_sc_az, sun_sc_el, ~] = cart2sph(sun_sc(3,:), sun_sc(1,:), sun_sc(2,:));
    
    %%%
    % Solar aspect angle (w.r.t z-axis in S/C frame, '+' above y-z plane, '-' below)
    Phi = rad2deg(sun_sc_az);

    %%%
    % Solar elevation angle (w.r.t x-z-plane in S/C frame, [-90,+90], '+' above x-z plane, '-' below)
    Xi = rad2deg(sun_sc_el);

    %%%
    % Find direction of the origin/target in S/C frame:
    if (id_origin == cspice_bodn2c('CHURYUMOV-GERASIMENKO') || id_origin == cspice_bodn2c('Earth') ...
            || id_origin == cspice_bodn2c('Mars') || id_origin == cspice_bodn2c('LUTETIA') || ...
            id_origin == cspice_bodn2c('STEINS'))
        
        if ~isOnWorker
            spmd
                com_sc = NaN(3, length(et_local));
                if (any(found))
                    com_sc(:, found) = cspice_spkpos(cspice_bodc2n(id_origin), et_local(found), ...
                        'ROS_SPACECRAFT', 'LT+S', object);
                end
            end
            com_sc = cat(2, com_sc{:});
        else
            com_sc = NaN(3, length(et));
                if (any(found))
                    com_sc(:, found) = cspice_spkpos(cspice_bodc2n(id_origin), et(found), ...
                        'ROS_SPACECRAFT', 'LT+S', object);
                end
        end
        %%%
        % Transform to spherical coordinates about y-axis (i.e. x,y,z -> z,x,y):
        [com_az, com_el, ~] = cart2sph(com_sc(3,:), com_sc(1,:), com_sc(2,:));

        %%%
        % Origin/target aspect angle (w.r.t z-axis in S/C frame, '+' above y-z plane, '-' below)
        Psi = rad2deg(com_az);

        %%%
        % Origin/target elevation angle (w.r.t x-z-plane in S/C frame, [-90,+90], '+' above x-z plane, '-' below)
        Chi = rad2deg(com_el);
    end

    %% Find RPC-LAP illumination conditions
    % This is only done when _object_ is Rosetta:
    if (id == -226 || id == -226000)

        %%% 
        % *Currently unused code for finding illumination boundary angles for
        % arbitrary solar array orientation (though still assumed to have 
        % symmetry axis perpendicular to the Sun, i.e. SEA = 0):*

        %%%
        % Get solar array NAIF codes:
        %
        %   id_SA1 = id_str - 15;   % +Ysc array
        %   id_SA2 = id_str - 25;   % -Ysc array

        %%%
        % Get change of basis transformation matrices:
        %
        %   [cmat_SA1, clkout_SA1, found_SA1] = cspice_ckgp(id_SA1, et_s, 0, 'ROS_SPACECRAFT');
        %   [cmat_SA2, clkout_SA2, found_SA2] = cspice_ckgp(id_SA2, et_s, 0, 'ROS_SPACECRAFT');

        %%%
        % Alternative obtainment of the transformation matrices:
        %
        %   rot_SA1 = cspice_pxform('ROS_SPACECRAFT', 'ROS_SA+Y', et);
        %   rot_SA2 = cspice_pxform('ROS_SPACECRAFT', 'ROS_SA-Y', et);

        %%%
        % Compute the inverse of the change of basis transformatation matrix (the 
        % COLUMNS of which are the the basis vectors of the instrument frame expressed in
        % the S/C frame):
        %
        %   [~, ~, num] = size(cmat);
        %   basis_SA1 = zeros(size(cmat_SA1));
        %   basis_SA2 = zeros(size(cmat_SA2));

            %%%
            % The transformation matrix between two ortho-normal bases on the same
            % vector space is orthogonal, hence cmat^-1 = cmat^T, which is faster.
            %
            %   for i = 1:num
            %       basis_SA1(:,:,i) = cmat_SA1(:,:,i)';
            %       basis_SA2(:,:,i) = cmat_SA2(:,:,i)';
            %   end

        %%%
        % Solar array gimbal positions [m] (from RO-DSS-IF-1201 Issue 3):
        %
        %   pos_SA1 = [0, 1.0645, 1.32113]';
        %   pos_SA2 = [0, -1.0645, 1.32113]';

        %%%
        % Solar array half-width [m] (from RO-DSS-IF-1201 Issue 3)
        % 
        %   SA_HW = 1.125;

        %%%
        % RPC-LAP positions [m] (from EAICD-1_8)
        % In S/C frame:
        %
        %   lap1_pos = [-1.19, 2.43, 3.88]';
        %   lap2_pos = [-2.48, 0.78, -0.65]';

        %%%
        % In solar array frames:
        %
        %   lap1_pos_SA1 = zeros(3, num);
        %   lap1_pos_SA2 = zeros(3, num);
        %   for i = 1:num
        %       lap1_pos_SA1(:,i) = cmat_SA1(:,:,i)*(lap1_pos - pos_SA1);
        %       lap1_pos_SA2(:,i) = cmat_SA2(:,:,i)*(lap1_pos - pos_SA2);
        %   end

        %%%
        % Check illumination:
        % Probe 1 (c.f. lap1geo.pdf):
        %
        %   Phi11 = 131.6;
        %   Phi12 = 178.6;

        %%%
        % *Anders values* (converted to the present solar aspect angle definition
        % by ADDING 90 degrees):
        %
        %   Phi11 = 131;
        %   Phi12 = 181;

        %%%
        % *My values* (from photoemission study):
        Phi11 = 131.2; Phi11b = 132.2;
        Phi12 = 179.2; Phi12b = 178.2;
        lap1_ill_full = (round(10*Phi)/10 <= Phi11)' | (round(10*Phi)/10 >= Phi12)';
        lap1_shade_full = (round(10*Phi)/10 >= Phi11b)' & (round(10*Phi)/10 <= Phi12b)';
        lap1_partial_shade = ~lap1_ill_full & ~lap1_shade_full;

        %%%
        % Alternative obtainment of illumination logical (for arbitrary SA
        % orientation, though still with sym axis perpendicular to the Sun):
        %
        %   lap1_ill = (abs(lap1_pos_SA1(1,:)) > SA_HW);

        %%%
        % Probe 2 (c.f. lap2geo.pdf):
        Phi21 = 20; % Never appears to go below this during entire mission
        Phi22 = 82.2; Phi22b = 81.2;    % Empirically from data
        Phi23 = 110.5;  % Calulated trigonometrically from S/C drawings
        lap2_ill_full = ((round(10*Phi)/10 <= Phi21) | (round(10*Phi)/10 >= Phi22))' ...
            - 0.6*((round(10*Phi)/10 >= Phi22) & (round(10*Phi)/10 <= Phi23))';
        lap2_shade_full = (round(10*Phi)/10 > Phi21)' & (round(10*Phi)/10 <= Phi22b)';
        
        %%% Probe 2 HGA shading
        lap2_HGA_range = lap2_ill_full == 0.4;
        if any(lap2_HGA_range)
            % LAP2 is (at least partially) shaded by HGA iff the projection of
            % any point on the HGA onto the LAP2 terminator plane is within a
            % probe radius of the LAP2 center.
            % Obtain change of basis transformation matrix from spacecraft
            % frame to ROS_HGA_az frame (-226072):
            if ~isOnWorker
                et_s_HGA = distributed(gather(et_s(lap2_HGA_range)));
                spmd
                    et_s_HGA_local = getLocalPart(et_s_HGA);
                    [cmat_HGA_az, ~, found] = cspice_ckgp(-226072, et_s_HGA_local, 0, 'ROS_SPACECRAFT');
                    cmat_HGA_az(:,:,~found) = NaN(3,3, numel(find(~found)));
                    if ~local_loaded
                        cspice_unload([local_kernelFolder '/' local_kernelFile]);
                    end
                end
                cmat_HGA_az = cat(3, cmat_HGA_az{:});
            else
                et_s_HGA = et_s(lap2_HGA_range);
                cmat_HGA_az = cspice_ckgp(-226072, et_s_HGA, 0, 'ROS_SPACECRAFT');
            end

            %%%
            % Inverse of the change of basis transformation matrix has columns
            % which are the basis vectors of ROS_HGA_az in the ROS_SPACECRAFT
            % frame:
            HGA_az_basis = zeros(size(cmat_HGA_az));
            for i = 1:size(cmat_HGA_az, 3)
                HGA_az_basis(:,:,i) = cmat_HGA_az(:,:,i)';
            end

            %%%
            % Basis vectors of ROS_HGA in the ROS_SPACECRAFT frame:
            HGA_basis = [-HGA_az_basis(:,3,:) HGA_az_basis(:,2,:) HGA_az_basis(:,1,:)];

            %%%
            % Geometrical parameters
            r_LAP2 = [-2.48; 0.78; -0.65];
            R_LAP = 0.025;
            r_gimbal = [2.15153; 0; 0.080]; % RO-DSS-IF-1203 Issue 3 [SYS 01-1/5] 
            C_HGA = 1.3045;                 % --------------"------------------
            R_HGA = 1.100;                  % --------------"------------------

            %%%
            % Probe terminator plane normal vector:
            r_LAP2_exp = repmat(r_LAP2,1,numel(find(lap2_HGA_range)));
            n = reshape((sun_sc(:,lap2_HGA_range)-r_LAP2_exp)./...
                repmat(sqrt(sum((sun_sc(:,lap2_HGA_range)-r_LAP2_exp).^2, 1)),3,1), ...
                3, 1, size(cmat_HGA_az, 3));
            %%%
            % HGA boresight components:
            z_HGA = HGA_basis(:,3,:);
            %%%
            % HGA center coordinates:
            r_HGA_center = repmat(r_gimbal,[1 1 size(r_LAP2_exp,2)]) + C_HGA*HGA_basis(:,1,:) ...
                + 0.160*HGA_basis(:,3,:);

            %%%
            % Setup minimization problem:
            % Quadratic objective funtion (for each point in R^3, the distance
            % of the point's projection onto the LAP2 terminator plane to the
            % LAP2 center):
            n_T = permute(n, [2 1 3]);
            n2 = arrayfun(@(x) n(:,:,x)*n_T(:,:,x), 1:size(n,3), 'uni', false);
            n2 = cat(3, n2{:});
            A = repmat(eye(3),[1 1 size(n,3)]) - n2;
            %%%
            % A is a symmetric idempotent matrix, thus Q = A^T*A = A^2 = A:
            Q = A;
            f = zeros(size(A,1),1,size(A,3));
            c = zeros(1,1,size(A,3));
            for i = 1:size(f,3)
                f(:,:,i) = -A(:,:,i)*r_LAP2;
                c(:,:,i) = r_LAP2'*A(:,:,i)*r_LAP2/2;
            end

            %%%
            % Quadratic (in-)equality constraint (distance of point to HGA
            % center):
            z_HGA_T = permute(z_HGA, [2 1 3]);
            z2 = arrayfun(@(x) z_HGA(:,:,x)*z_HGA_T(:,:,x), 1:size(z_HGA,3), 'uni', false);
            z2 = cat(3, z2{:});
            B = repmat(eye(3),[1 1 size(z_HGA_T,3)]) - z2;
            %%%
            % B is a symmetric idempotent matrix, thus H = B^T*B = B^2 = B:
            H = 2*B;
            k = zeros(size(B,1),1,size(B,3));
            d = zeros(1,1,size(B,3));
            for i = 1:size(k,3)
                k(:,:,i) = -2*B(:,:,i)*r_HGA_center(:,:,i);
                d(:,:,i) = r_HGA_center(:,:,i)'*B(:,:,i)*r_HGA_center(:,:,i) - R_HGA;
            end

            %%%
            % Linear equality constraint (point in HGA plane):
            Aeq = z_HGA_T;
            beq = zeros(size(Aeq, 1), 1, size(Aeq, 3));
            for i = 1:size(Aeq,3)
                beq(:,:,i) = z_HGA_T(:,:,i)*r_HGA_center(:,:,i);
            end
            
            %%%
            % Execute minimization:
            r_min = NaN(3, size(Q, 3));
            fmin = NaN(size(Q, 3), 1);
            eflag = NaN(size(Q, 3), 1);
            r_min_eq = NaN(3, size(Q, 3));
            fmin_eq = NaN(size(Q, 3), 1);
            eflag_eq = NaN(size(Q, 3), 1);
           % twID= fopen('/Users/frejon/Documents/MATLAB/orbit_out.txt','w')
            hga_indz= find(lap2_HGA_range);

            for i = 1:100:size(Q, 3)
                options = optimoptions(@fmincon,'Algorithm','interior-point',...
                    'GradObj','on','GradConstr','on',...
                    'HessFcn',@(x,lambda)quadhess(x,lambda,Q(:,:,i),H(:,:,i)), ...
                    'Display', 'off');
                fun = @(x)quadobj(x,Q(:,:,i),f(:,:,i),c(:,:,i));
                nonlconstr = @(x)quadconstr(x,H(:,:,i),k(:,:,i),d(:,:,i));
                x0 = r_HGA_center(:,:,i);
                if any(isnan(x0))
                    continue;
                end
                [r_min(:,i), fmin(i), eflag(i)] = fmincon(fun,x0,...
                    [],[],Aeq(:,:,i),beq(:,:,i),[],[],nonlconstr,options);
                options_eq = optimoptions(@fmincon,'Algorithm','interior-point',...
                    'GradObj','on','GradConstr','on',...
                    'HessFcn',@(x,lambda)quadhess_eq(x,lambda,Q(:,:,i),H(:,:,i)), ...
                    'Display', 'off');
                nonlconstr_eq = @(x)quadconstr_eq(x,H(:,:,i),k(:,:,i),d(:,:,i));
                [r_min_eq(:,i), fmin_eq(i), eflag_eq(i)] = fmincon(fun,x0,...
                    [],[],Aeq(:,:,i),beq(:,:,i),[],[],nonlconstr_eq,options_eq);
                
                %fprintf(twID,'%f,%f,%f,%f,%f,%f\n',fmin,r_HGA_center(:,1,i),Phi(hga_indz(i)),Xi(hga_indz(i)));
                
                
            end
            %fclose(twID);
%             r_min_proj = squeeze(reshape(r_min,3,1,size(n,3)) - dot(reshape(r_min,3,1,size(n,3))-r_LAP2, n).*n);
%             r_min_proj_eq = squeeze(reshape(r_min_eq,3,1,size(n,3)) - dot(reshape(r_min_eq,3,1,size(n,3))-r_LAP2, n).*n);

            LAP2_HGA_ill = sqrt(fmin) > R_LAP;
            LAP2_HGA_full_shade = ~LAP2_HGA_ill & sqrt(fmin_eq) > R_LAP;
           % LAP2_HGA_partial_shade = ~LAP2_HGA_ill & ~LAP2_HGA_full_shade;
            
            LAP2_HGA_ill(isnan(fmin)) = 0.4*ones(numel(find(isnan(fmin))), 1);
            LAP2_HGA_full_shade(isnan(fmin)) = 0.4*ones(numel(find(isnan(fmin))), 1);
           % LAP2_HGA_partial_shade(isnan(fmin)) = 0.4*ones(numel(find(isnan(fmin))), 1);
            
            lap2_ill_full(lap2_HGA_range) = LAP2_HGA_ill;
            lap2_shade_full(lap2_HGA_range) = LAP2_HGA_full_shade;
        end
    end

    %% Compute position of sub-spacecraft point:
    % try
    %     subpoint = zeros(3, length(et));
    %     for i = 1:length(et)
    %       [subpoint(:,i), trgepc, srfvec] = cspice_subpnt('Intercept: ellipsoid', origin, et(i), ref, 'LT+S', object);
    %     end
    %     subpoint_s = S(subpoint(1:3,:));
    %     subpoint_latitude = 90-180/pi*subpoint_s(2,:)';
    %     subpoint_longitude = 180/pi*subpoint_s(3,:)';
    % catch
    %     % Ignore if error.
    % end

    %% Output
    % Several output formats are possible depending on the number of output
    % arguments given.
    out_struct = struct;
    %out_struct.('UTC') = cellstr(cspice_et2utc(et, 'ISOC', 3));
    %out_struct.('epoch') = et';
    %out_struct.('position') = state(1:3,:)';
%     out_struct.('radial_distance') = radial_distance';
%     out_struct.('latitude') = latitude';
%     out_struct.('longitude') = longitude';
%     out_struct.fmin = fmin;
%     out_struct.HGA_basis=HGA_basis;
%     if (exist('subpoint_latitude', 'var'))
%         out_struct.('subpoint_latitude') = subpoint_latitude;
%     end
%     if (exist('subpoint_longitude', 'var'))
%         out_struct.('subpoint_longitude') = subpoint_longitude;
%     end
 %   [out_struct.('x_sc'), out_struct.('y_sc'), out_struct.('z_sc')] = ...
 %       deal(squeeze(basis_n(:,1,:))', squeeze(basis_n(:,2,:))', squeeze(basis_n(:,3,:))');
    out_struct.('SAA') = Phi';
    out_struct.('SEA') = Xi';
%     if (id_origin == cspice_bodn2c('CHURYUMOV-GERASIMENKO'))
%         out_struct.('CAA') = Psi';
%         out_struct.('CEA') = Chi';
%     end
%     if (id_origin == cspice_bodn2c('Earth'))
%         out_struct.('EAA') = Psi';
%         out_struct.('EEA') = Chi';
%     end
%     if (id_origin == cspice_bodn2c('Mars'))
%         out_struct.('MAA') = Psi';
%         out_struct.('MEA') = Chi';
%     end
%     if (id_origin == cspice_bodn2c('LUTETIA') || id_origin == cspice_bodn2c('STEINS'))
%         out_struct.('AAA') = Psi';
%         out_struct.('AEA') = Chi';
%     end
%     out_struct.('sun_position') = sun';
%     out_struct.('sun_latitude') = sun_lat';
%     out_struct.('sun_longitude') = sun_lon';
%     out_struct.('heliocentric_distance') = cspice_convrt(sun_distance, 'km', 'au')';
%     out_struct.('SZA') = sza;
%     out_struct.('LAP1_ill_lims') = [Phi11 Phi12];
%     out_struct.('LAP2_ill_lims') = [Phi21 Phi22 Phi23];
%     out_struct.('lap1_ill_full') = lap1_ill_full;
%     out_struct.('lap1_shade_full') = lap1_shade_full;
%     out_struct.('lap2_ill_full') = lap2_ill_full;
    %out_struct.('lap2_shade_full') = lap2_shade_full;
    out_struct.('LAP1_ill') = (lap1_ill_full + 0.2*(~lap1_ill_full & ...
        ~lap1_shade_full)).*(out_struct.SEA < 1) + 0.3*(~(out_struct.SEA < 1));
    out_struct.('LAP2_ill') = (lap2_ill_full + 0.2*(~lap2_ill_full & ...
        ~lap2_shade_full)).*(out_struct.SEA < 1) + 0.3*(~(out_struct.SEA < 1));
    varargout = {out_struct};
    
else
    in_struct = varargin{cellfun(@(x) isstruct(x), varargin)};
    inds = in_struct.epoch >= min(et) & in_struct.epoch <= max(et);
    fields = fieldnames(in_struct);
    out_struct = struct;
    for i = 1:length(fields)
        tmp = in_struct.(fields{i});
        if (size(tmp, 2) == numel(in_struct.epoch))
            out_struct.(fields{i}) = tmp(inds);
        else
            out_struct.(fields{i}) = tmp;
        end
    end
    id_origin = cspice_bodn2c(origin);
    id = cspice_bodn2c(object);
    id = -sign(id)*id;
    et = in_struct.epoch;
    sun_n = (in_struct.sun_position./repmat(in_struct.heliocentric_distance, 1, 3))';
    Phi11 = in_struct.LAP1_ill_lims(1);
    Phi12 = in_struct.LAP1_ill_lims(2);
    Phi21 = in_struct.LAP2_ill_lims(1);
    Phi22 = in_struct.LAP2_ill_lims(2);
    Phi23 = in_struct.LAP2_ill_lims(3);
    lap1_ill = ((in_struct.SAA < Phi11) | (in_struct.SAA > Phi12));
    lap2_ill = ((in_struct.SAA < Phi21) | (in_struct.SAA > Phi22)) - ...
        0.6*((in_struct.SAA > Phi22) & (in_struct.SAA < Phi23));
end

%% Plotting
% If no output argument is provided, or if axes ARE provided, give results 
% in the form of plots.

%%%
% Check if axes are given as input arguments:
if (nargin > 4)
    input_axes = cell2mat(cellfun(@(x) all(ishandle(x)), varargin, 'uni', false));
    if (any(input_axes))
        given_axes = varargin{input_axes};
    else
        given_axes = [];
    end
else
    input_axes = false;
end

if (nargout == 0 || input_axes)
    %%%
    % If aux_data given, set marker color and size:
    if (aux_data)
        CData = varargin{cellfun(@(x) isfloat(x), varargin)};
        markerSize = 36;
%         colormap('jet');
    end
            
    %%%
    % Get reference body radius:
    radii = cspice_bodvrd(origin, 'RADII', 3);
    %%%
    % Normalization/axes units:
    if (id_origin == cspice_bodn2c('EARTH') || id_origin == cspice_bodn2c('Mars'))
        R_0 = radii(1);
        units = 'R_0';
    elseif (id_origin == cspice_bodn2c('Sun'))
        %%%
        % 1 AU (km):
        R_0 = 149597870;
        units = 'AU';
    else
        R_0 = 1;
        units = 'km';
    end
    %%
    % * *Plot 3D*
    %
    % Check if axes handle given or plot to new figure:
    if (any(input_axes) && given_axes(1) ~= 0)
        axes(given_axes(1));
        plot1_on = true;
    elseif (any(input_axes) && given_axes(1) == 0)
        plot1_on = false;
    else
        figure('PaperType', 'A4', 'PaperOrientation', 'landscape', ...
                'PaperPositionMode', 'auto');
        set(gcf, 'Units', get(gcf, 'PaperUnits'));
        pcm = get(0,'ScreenPixelsPerInch')/2.54;
        set(gcf, 'Position', [0 930/pcm get(gcf, 'PaperSize')]);
        plot1_on = true;
    end
    
    if (plot1_on)
        %%%
        % Draw origin model:
        if ((id_origin == cspice_bodn2c('CHURYUMOV-GERASIMENKO')) && (strcmpi(ref, '67P/C-G_ck') || length(et) == 1))
            %%%
            % Render shape model:
            [V,F] = read_vertices_and_faces_from_obj_file('ESA_Rosetta_OSIRIS_67P_SHAP2P.obj');
            V = V*2.5;
            h = trisurf(F,V(:,1),V(:,2),V(:,3),'FaceColor',[0.7,0.7,0.7], 'EdgeColor', 'none');
            light('Position',[-1.0,-1.0,100.0],'Style','infinite');
            lighting phong;
            shape_model = true;
        else
            [X, Y, Z] = ellipsoid(0, 0, 0, radii(1)/R_0, radii(2)/R_0, radii(3)/R_0, 20);
            colormap gray;
            h = surf(X,Y,Z, 'CDataMapping', 'direct', 'FaceColor', 'texturemap');
            shape_model = false;
        end
        set(gca, 'FontSize', 14);
        hAnnotation = get(h, 'Annotation');
        hLegendEntry = get(hAnnotation, 'LegendInformation');
        set(hLegendEntry, 'IconDisplayStyle', 'off');
        hold on;

        %%%
        % Plot trajectory and orientation of object:
        a = out_struct.position(:,1)'/R_0;
        b = out_struct.position(:,2)'/R_0;
        c = out_struct.position(:,3)'/R_0;
        if (length(et) == 1)
            %%%
            % Draw position vector:
            quiver3(0, 0, 0, a, b, c, 0, 'k', 'LineWidth', 1.2, 'DisplayName', ...
                [object ' position vector']);
            %%%
            % Draw orientation in the form of S/C frame basis vectors
%               quiver3(a, b, c, basis_n(1,1,1)/R_0, basis_n(2,1,1)/R_0, basis_n(3,1,1)/R_0, ...
%                   'g', 'LineWidth', 1.2, 'DisplayName', ['x ' object ' S/C frame']);
%               quiver3(a, b, c, basis_n(1,2,1)/R_0, basis_n(2,2,1)/R_0, basis_n(3,2,1)/R_0, ...
%                   'm', 'LineWidth', 1.2, 'DisplayName', ['y ' object ' S/C frame']);
%               quiver3(a, b, c, basis_n(1,3,1)/R_0, basis_n(2,3,1)/R_0, basis_n(3,3,1)/R_0, ...
%                   'b', 'LineWidth', 1.2, 'DisplayName', ['z ' object ' S/C frame']);
%               scatter3(a, b, c, 'k', 'filled', 'DisplayName', object);
            
            %%%
            % Old axis definitions:
            %   axis(min(max(state_s(1,:)), 10*R_0)*[-1 1 -1 1 -1 1])
            %   axis(min(max(state_s(1,:)/R_0), 10)*[-1 1 -1 1 -1 1])
            
            %%%
            % Current axis definitions:
            axis([-max(abs(state(1,:))), max(abs(state(1,:))), -max(abs(state(2,:))), ...
                max(abs(state(2,:))), -max(abs(state(3,:))), max(abs(state(3,:)))]/R_0, 'equal')
        else
            if (strcmpi(frame, 'terminal') == 0 && strcmpi(frame, 'J2000') == 0 && ...
                    strcmpi(frame, 'ECLIPJ2000') == 0)
                set(h, 'FaceColor', [0.7 0.7 0.7]);
            end
            %%%
            % Trajectory:
            %
            % If numerical vector supplied, colorcode trajectory:
            if (aux_data)
                scatter3(a, b, c, markerSize, CData, 'fill', 'DisplayName', [object ' trajectory']);
                set(gca, 'clim', [min(CData) max(CData)]);
                Cbar = colorbar;
                set(Cbar, 'FontSize', get(gca, 'FontSize'))
                set(gcf, 'renderer', 'zbuffer')
            else
                plot3(a, b, c, 'k', 'LineWidth', 2, 'DisplayName', [object ' trajectory']);
            end
            %%%
            % Orientation:
%               Q_scale = 0.25;
%               Q_step = 50;
%               quiver3(a(1:Q_step:end), b(1:Q_step:end), c(1:Q_step:end), ...
%                   squeeze(basis_n(1,1,1:Q_step:end))', squeeze(basis_n(2,1,1:Q_step:end))', ...
%                   squeeze(basis_n(3,1,1:Q_step:end))', Q_scale, 'g', 'DisplayName', ['x ' object ' S/C frame'])
%               quiver3(a(1:Q_step:end), b(1:Q_step:end), c(1:Q_step:end), ...
%                   squeeze(basis_n(1,2,1:Q_step:end))', squeeze(basis_n(2,2,1:Q_step:end))', ...
%                   squeeze(basis_n(3,2,1:Q_step:end))', Q_scale, 'm', 'DisplayName', ['y ' object ' S/C frame'])
%               quiver3(a(1:Q_step:end), b(1:Q_step:end), c(1:Q_step:end), ...
%                   squeeze(basis_n(1,3,1:Q_step:end))', squeeze(basis_n(2,3,1:Q_step:end))', ...
%                   squeeze(basis_n(3,3,1:Q_step:end))', Q_scale, 'b', 'DisplayName', ['z ' object ' S/C frame'])
            
            %%%
            % Old axis definitions:
            %   axis(max(state_s(1,:))*[-1 1 -1 1 -1 1]);
            %   axis(max(state_s(1,:)/R_0)*[-1 1 -1 1 -1 1]);
            
            %%%
            % Current axis definitions:
            axis([-max(abs(out_struct.position(:,1))), max(abs(out_struct.position(:,1))), -max(abs(out_struct.position(:,2))), ...
                max(abs(out_struct.position(:,2))), -max(abs(out_struct.position(:,3))), max(abs(out_struct.position(:,3)))]/R_0, 'equal')
            
            %%%
            % Draw 2D projections on plot box boundaries:
            bounds = axis;
            xmin = bounds(1);
            xmax = bounds(2);
            ymin = bounds(3);
            ymax = bounds(4);
            zmin = bounds(5);
            zmax = bounds(6);
            v = (0:1/20:1)'*2*pi;        
            %%%
            % Vertical projection:
            plot3(a, b, zmin*ones(size(c)), 'k--', 'LineWidth', 0.8, 'HandleVisibility','off');
            %%%
            % Horizontal projections:
            [az, ~] = view;
            if (az >= -90 && az <= 90)
                xplane = xmax;
            else
                xplane = xmin;
            end
            if(az >= 0 && az <= 180)
                yplane = ymin;
            else
                yplane = ymax;
            end
            plot3(xplane*ones(size(a)), b, c, 'k--', 'LineWidth', 0.8, 'HandleVisibility','off');
            plot3(a, yplane*ones(size(b)), c, 'k--', 'LineWidth', 0.8, 'HandleVisibility','off');
            %%%
            % Origin model projections:
            if (strcmpi(ref, '67P/C-G_ck'))
                p1 = trisurf(F,V(:,1),V(:,2),zmin*ones(size(V(:,3))),'FaceColor',[0.45,0.45,0.45], ...
                    'CDataMapping', 'direct', 'EdgeColor', 'none', 'FaceAlpha', 1);
                p2 = trisurf(F,xplane*ones(size(V(:,2))),V(:,2),V(:,3),'FaceColor',[0.9,0.9,0.9], ...
                    'CDataMapping', 'direct', 'EdgeColor', 'none', 'FaceAlpha', 1);
                p3 = trisurf(F,V(:,1),yplane*ones(size(V(:,2))),V(:,3),'FaceColor',[0.9,0.9,0.9], ...
                    'CDataMapping', 'direct', 'EdgeColor', 'none', 'FaceAlpha', 1);
            else
                %%%
                % Vertical:
                p1 = surf(X,Y,ones(size(Z))*min(zlim), 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.5 0.5 0.5]);
                %%%
                % Horizontal:
                p2 = surf(xplane*ones(size(X)), Y, Z, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.5 0.5 0.5]);
                p3 = surf(X, yplane*ones(size(Y)), Z, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.5 0.5 0.5]);
            end
            %%%
            % Turn off model projection legend entries:
            p1Annotation = get(p1, 'Annotation');
            p1LegendEntry = get(p1Annotation, 'LegendInformation');
            set(p1LegendEntry, 'IconDisplayStyle', 'off');
            p2Annotation = get(p2, 'Annotation');
            p2LegendEntry = get(p2Annotation, 'LegendInformation');
            set(p2LegendEntry, 'IconDisplayStyle', 'off');
            p3Annotation = get(p3, 'Annotation');
            p3LegendEntry = get(p3Annotation, 'LegendInformation');
            set(p3LegendEntry, 'IconDisplayStyle', 'off');
        end
        
        %%%
        % Axis labels:
        xlabel(['x (' units ')'])
        ylabel(['y (' units ')'])
        zlabel(['z (' units ')'])

        %%%
        % Plot direction to Sun:
        if (length(et) == 1 || strcmpi(frame, 'terminal') || strcmpi(frame, 'J2000') ...
                || strcmpi(frame, 'ECLIPJ2000') || strcmpi(frame, 'GSE') || strcmpi(frame, 'GSM'))
            sl = min(abs(axis));
            quiver3(1.1*sun_n(1)*radii(1)/R_0, 1.1*sun_n(2)*radii(2)/R_0, 1.1*sun_n(3)*radii(3)/R_0, sl*sun_n(1), sl*sun_n(2), sl*sun_n(3), ...
                'r', 'LineWidth', 2, 'DisplayName', 'Sun');
            %%%
            % Plot shading on |origin| surface:
            if (shape_model && length(et) == 1)
                l = findobj(gcf, 'type', 'light');
                set(l, 'Position', sun_n);
            else
                Cmap = gray(64);
                C = 24 + 32*ones(size(Z)).*(X*sun_n(1) + Y*sun_n(2) + Z*sun_n(3) > 0);
                true_C = zeros(size(C, 1), size(C, 2), 3);
                for i = 1:size(C, 1)
                    for j = 1:size(C, 2)
                        true_C(i,j,:) = Cmap(C(i,j));
                    end
                end
                set(h, 'CData', true_C);
            end
        end

        %%%
        % Legend:
        l = legend('Location', 'NorthEast');
        set(l, 'box', 'off', 'color', 'none');
        hold off;
    end

    %% Plot coordinates
    if(length(et) > 1)
        %%% * *Plot latitude, longitude, solar zenith angle and spin phase*
        % Check if axes handle given or plot to new figure:
        if (any(input_axes) && given_axes(2) ~= 0)
            h = given_axes(2);
            plot2_on = true;
        elseif (any(input_axes) && given_axes(2) == 0)
            plot2_on = false;
        elseif (length(et) > 1)
            figure('PaperType', 'A4', 'PaperOrientation', 'landscape', ...
                'PaperPositionMode', 'auto');
            set(gcf, 'Units', get(gcf, 'PaperUnits'));
            pcm = get(0,'ScreenPixelsPerInch')/2.54;
            set(gcf, 'Position', [640/pcm 930/pcm get(gcf, 'PaperSize')]);
            h = gca;
            set(h(1), 'FontSize', 18);
            plot2_on = true;
        else
            plot2_on = false;
        end
        
        if (plot2_on && ~aux_data)
            colors = [[0 0 0]; [1 0 0]; [0 0.5 0]; [0 0 1]];
            set(h(1), 'NextPlot', 'add', 'colororder', colors);
            plot(h(1), et, [out_struct.latitude out_struct.longitude out_struct.SZA out_struct.sun_longitude], 'LineWidth', 2);
            set(get(h(1), 'XLabel'), 'FontSize', get(h(1), 'FontSize'));
            set(get(h(1), 'YLabel'), 'string', 'Angle (\circ)', 'FontSize', get(h(1), 'FontSize'));
            l_strings = {'Lat', 'Lon', 'SZA', 'Lon_{sun}' };
            l = gobjects(numel(l_strings),1);
            for i = 1:length(l)
                l(i) = text(1.01, 1.0, l_strings(i), 'Parent', h(1), 'Units', 'normalized', ...
                    'FontSize', get(h(1), 'FontSize'), 'tag', 'legend', 'color', colors(i,:));
            end
            %%%
            % Adjust vertical positions of legend text objects:
            for i = 2:length(l)
                ext = get(l(i-1), 'Extent');
                set(l(i), 'Position', get(l(i-1), 'Position')-[0 ext(end) 0])
            end
            limY = get(h(1), 'ylim');
            axis(h(1), 'tight');
            set(h(1), 'ylim', limY, 'XTick', []);
            dcm_obj = datacursormode(get(h(1), 'Parent'));
            set(dcm_obj, 'UpdateFcn', {@lap.datacursor_updatefunction, 'et'})
            %%%
            % Make timeaxis:
            irf_timeaxis(h(1), irf_time(0, 'tt>epoch'));
            grid(h(1), 'on');
            %%%
            % Remove date label from x-axis:
            set(get(h(1), 'xlabel'), 'string', '');
            %%%
            % Annotate Sun latitude:
            if (strcmp(sprintf('%1.1f', max(out_struct.sun_latitude)), sprintf('%1.1f', min(out_struct.sun_latitude))))
                Lat_str = 'Lat_{sun} = ';
            else
                Lat_str = 'Lat_{sun} \approx ';
            end
            set(get(gca, 'xlabel'), 'Units', 'normalized')
            L = text(1.0, get(get(gca, 'xlabel'), 'Position')*[0 1 0]', {[Lat_str sprintf('%1.1f', mean(out_struct.sun_latitude)) '^\circ']}, ...
                'Parent', h(1), 'FontSize', get(gca, 'FontSize'), 'Units', 'normalized', ...
                'HorizontalAlignment', 'right', 'Tag', 'Sun_Lat_Annotation', 'VerticalAlignment', 'Top');
        elseif (plot2_on && aux_data)
            axes(h(1));
            scatter(out_struct.longitude, out_struct.latitude, markerSize, CData, 'fill')
            grid(h(1), 'on');
            set(get(h(1), 'xlabel'), 'string', 'Longitude (deg)')
            set(get(h(1), 'ylabel'), 'string', 'Latitude (deg)')
            Cbar2 = colorbar('peer', h(1));
            set(Cbar2, 'FontSize', get(h(1), 'FontSize'))
            set(h(1), 'clim', [min(CData) max(CData)]);
            set(h(1), 'FontSize', 14);
        end
    
        %%% * *Plot radial distance*
        % Check if axes handle given or plot to new figure:
        if (any(input_axes) && given_axes(3) ~= 0)
            h = given_axes(3);
            plot3_on = true;
        elseif (any(input_axes) && given_axes(3) == 0)
            plot3_on = false;
        elseif (length(et) > 1 && ~aux_data)
            figure('PaperType', 'A4', 'PaperOrientation', 'landscape', ...
                'PaperPositionMode', 'auto');
            set(gcf, 'Units', get(gcf, 'PaperUnits'));
            pcm = get(0,'ScreenPixelsPerInch')/2.54;
            set(gcf, 'Position', [640/pcm 0 get(gcf, 'PaperSize')]);
            h = gca;
            set(h(1), 'FontSize', 18);
            plot3_on = true;
        else
            plot3_on = false;
        end
        if (plot3_on && ~aux_data)
            colors = [[0 0 0]; [1 0 0]; [0 0.5 0]; [0 0 1]];
            set(h(1), 'NextPlot', 'add', 'colororder', colors);
            plot(h(1), et, [out_struct.radial_distance out_struct.position], 'LineWidth', 2);
            set(get(h(1), 'ylabel'), 'string', 'Distance (km)', 'FontSize', get(h(1), 'FontSize'));
            limY = get(h(1), 'ylim');
            axis(h(1), 'tight');
            set(h(1), 'ylim', limY, 'XTick', []);
            dcm_obj = datacursormode(get(h(1), 'Parent'));
            set(dcm_obj, 'UpdateFcn', {@lap.datacursor_updatefunction, 'et'})
            %%%
            % Make timeaxis:
            irf_timeaxis(h(1), irf_time(0, 'tt>epoch'));
            grid(h(1), 'on');
            %%%
            % Remove date label from x-axis:
            set(get(h(1), 'xlabel'), 'string', '');
            %%%
            % Make legend:
            if (strcmp(frame, '21/LUTETIA_CSO') || strcmp(frame, '2867/STEINS_CSO'))
                l_strings = {'r', ['x_{' frame(end-2:end) '}'], ['y_{' frame(end-2:end) '}'], ...
                    ['z_{' frame(end-2:end) '}']};
            else
                l_strings = {'r', ['x_{' strrep(frame, '_', '\_') '}'], ['y_{' strrep(frame, '_', '\_') '}'], ...
                    ['z_{' strrep(frame, '_', '\_') '}']};
            end
            l = gobjects(numel(l_strings),1);
            for i = 1:length(l)
                l(i) = text(1.01, 1.0, l_strings(i), 'Parent', h(1), 'Units', 'normalized', ...
                    'FontSize', get(h(1), 'FontSize'), 'tag', 'legend', 'color', colors(i,:));
            end
            %%%
            % Adjust vertical positions of legend text objects:
            for i = 2:length(l)
                ext = get(l(i-1), 'Extent');
                set(l(i), 'Position', get(l(i-1), 'Position')-[0 ext(end) 0])
            end
            R_sun = cspice_convrt(out_struct.heliocentric_distance', 'km', 'au');
            if (strcmp(sprintf('%1.2f', max(R_sun)), sprintf('%1.2f', min(R_sun))))
                R_str = 'R_{sun} = ';
            else
                R_str = 'R_{sun} \approx ';
            end
            set(get(gca, 'xlabel'), 'Units', 'normalized')
            L = text(1.1, get(get(gca, 'xlabel'), 'Position')*[0 1 0]', {[R_str sprintf('%1.2f', mean(R_sun)) ' AU']}, ...
                'Parent', h(1), 'FontSize', get(h(1), 'FontSize'), 'Units', 'normalized', ...
                'HorizontalAlignment', 'right', 'Tag', 'Sun_R_Annotation', 'VerticalAlignment', 'Top');
        end
    end
%%
    % * *Plot solar and comet aspect (& elevation) angles (for Rosetta)*
    if (id == -226 || id == -226000)
        %%%
        % Check if axes handle given or plot to new figure:
        if (any(input_axes) && given_axes(4) ~= 0)
            H = given_axes(4);
            plot4_on = true;
        elseif (any(input_axes) && given_axes(4) == 0)
            plot4_on = false;
        elseif (length(et) > 1)
            figure('PaperType', 'A4', 'PaperOrientation', 'landscape', ...
                'PaperPositionMode', 'auto');
            set(gcf, 'Units', get(gcf, 'PaperUnits'));
            set(gcf, 'Position', [0 0 get(gcf, 'PaperSize')]);
            H = gca;
            plot4_on = true;
            set(H, 'FontSize', 18);
        else
            plot4_on = false;
        end
        
        if (plot4_on)
            set(H(1), 'NextPlot', 'add');
            if (id_origin == cspice_bodn2c('CHURYUMOV-GERASIMENKO'))
                plot(H(1), et, out_struct.SAA, 'r', et, out_struct.CAA, 'b', ...
                    et, out_struct.CEA, 'g', et, out_struct.SEA, 'k', 'LineWidth', 2);
                set(H(1), 'ylim', [-180 180]);
                set(get(H(1), 'ylabel'), 'string', 'Attitude (deg)', 'FontSize', get(H(1), 'FontSize'));
                colors = [[1 0 0]; [0 0 1]; [0 1 0]; [0 0 0]];
                set(H(1), 'ColorOrder', colors);
                l_strings = {'SAA', [sprintf('\n\n') 'CAA'], [sprintf('\n\n\n\n') 'CEA'], ...
                    [sprintf('\n\n\n\n\n\n') 'SEA']};
                l = gobjects(numel(l_strings),1);
                set(H(1), 'Children', circshift(get(H(1), 'Children'), -1))
                for i = 1:length(l)
                    l(i) = text(1.01, 1.0, l_strings(i), 'Parent', H(1), 'Units', 'normalized', ...
                        'FontSize', get(H(1), 'FontSize'), 'tag', 'legend', 'color', colors(i,:));
                end
            elseif (id_origin == cspice_bodn2c('Earth'))
                plot(H(1), et, out_struct.SAA, 'r', et, out_struct.EAA, 'b', ...
                    et, out_struct.EEA, 'g', et, out_struct.SEA, 'k', 'LineWidth', 2);
                set(H(1), 'ylim', [-180 180]);
                set(get(H(1), 'ylabel'), 'string', 'Attitude (deg)', 'FontSize', get(H(1), 'FontSize'));
                colors = [[1 0 0]; [0 0 1]; [0 1 0]; [0 0 0]];
                set(H(1), 'ColorOrder', colors);
                l_strings = {'SAA', [sprintf('\n\n') 'EAA'], [sprintf('\n\n\n\n') 'EEA'], ...
                    [sprintf('\n\n\n\n\n\n') 'SEA']};
                l = gobjects(numel(l_strings),1);
                set(H(1), 'Children', circshift(get(H(1), 'Children'), -1))
                for i = 1:length(l)
                    l(i) = text(1.01, 1.0, l_strings(i), 'Parent', H(1), 'Units', 'normalized', ...
                        'FontSize', get(H(1), 'FontSize'), 'tag', 'legend', 'color', colors(i,:));
                end
            elseif (id_origin == cspice_bodn2c('Mars'))
                plot(H(1), et, out_struct.SAA, 'r', et, out_struct.MAA, 'b', ...
                    et, out_struct.MEA, 'g', et, out_struct.SEA, 'k', 'LineWidth', 2);
                set(H(1), 'ylim', [-180 180]);
                set(get(H(1), 'ylabel'), 'string', 'Attitude (deg)', 'FontSize', get(H(1), 'FontSize'));
                colors = [[1 0 0]; [0 0 1]; [0 1 0]; [0 0 0]];
                set(H(1), 'ColorOrder', colors);
                l_strings = {'SAA', [sprintf('\n\n') 'MAA'], [sprintf('\n\n\n\n') 'MEA'], ...
                    [sprintf('\n\n\n\n\n\n') 'SEA']};
                l = gobjects(numel(l_strings),1);
                set(H(1), 'Children', circshift(get(H(1), 'Children'), -1))
                for i = 1:length(l)
                    l(i) = text(1.01, 1.0, l_strings(i), 'Parent', H(1), 'Units', 'normalized', ...
                        'FontSize', get(H(1), 'FontSize'), 'tag', 'legend', 'color', colors(i,:));
                end
            elseif (id_origin == cspice_bodn2c('Lutetia') || id_origin == cspice_bodn2c('Steins'))
                plot(H(1), et, out_struct.SAA, 'r', et, out_struct.AAA, 'b', ...
                    et, out_struct.AEA, 'g', et, out_struct.SEA, 'k', 'LineWidth', 2);
                set(H(1), 'ylim', [-180 180]);
                set(get(H(1), 'ylabel'), 'string', 'Attitude (deg)', 'FontSize', get(H(1), 'FontSize'));
                colors = [[1 0 0]; [0 0 1]; [0 1 0]; [0 0 0]];
                set(H(1), 'ColorOrder', colors);
                l_strings = {'SAA', [sprintf('\n\n') 'AAA'], [sprintf('\n\n\n\n') 'AEA'], ...
                    [sprintf('\n\n\n\n\n\n') 'SEA']};
                l = gobjects(numel(l_strings),1);
                set(H(1), 'Children', circshift(get(H(1), 'Children'), -1))
                for i = 1:length(l)
                    l(i) = text(1.01, 1.0, l_strings(i), 'Parent', H(1), 'Units', 'normalized', ...
                        'FontSize', get(H(1), 'FontSize'), 'tag', 'legend', 'color', colors(i,:));
                end
            else
                plot(H(1), et, out_struct.SAA, 'r', 'LineWidth', 2);
                set(H(1), 'ylim', [0 180]);
                set(get(H(1), 'ylabel'), 'string', 'SAA (deg)', 'FontSize', get(H(1), 'FontSize'));
            end
            set(get(H(1), 'xlabel'), 'FontSize', get(H(1), 'FontSize'));
            set(H(1), 'xlim', [min(et) max(et)]);
            xl = get(H(1), 'xlim');
            %%%
            % Plot probe shade regions:
            colour = [0.4 0.4 0.4];
            alpha = 1;
            patch([xl(1) xl(1) xl(2) xl(2)], [Phi11 Phi12 Phi12 Phi11], colour, ...
                'FaceAlpha', alpha, 'EdgeColor', colour, 'EdgeAlpha', alpha, ...
                'HitTest', 'off', 'tag', 'ShadeAnnotation', 'UserData', 1, 'Parent', H(1));
            patch([xl(1) xl(1) xl(2) xl(2)], [Phi21 Phi22 Phi22 Phi21], colour, ...
                'FaceAlpha', alpha, 'EdgeColor', colour, 'EdgeAlpha', alpha, ...
                'HitTest', 'off', 'tag', 'ShadeAnnotation', 'UserData', 2, 'Parent', H(1));
            patch([xl(1) xl(1) xl(2) xl(2)], [Phi22 Phi23 Phi23 Phi22], 1-colour, ...
                'FaceAlpha', alpha, 'EdgeColor', 1-colour, 'EdgeAlpha', alpha, ...
                'HitTest', 'off', 'tag', 'ShadeAnnotation', 'UserData', 3, 'Parent', H(1));    
            text(H(1), xl(2), Phi12, 'Probe 1 shaded', ...
                'FontSize', get(H(1), 'FontSize'), 'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'right', 'tag', 'ShadeAnnotation', 'UserData', 1);
            text(H(1), xl(2), Phi21, 'Probe 2 shaded', ...
                'FontSize', get(H(1), 'FontSize'), 'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'right', 'tag', 'ShadeAnnotation', 'UserData', 2);
            text(H(1), xl(2), Phi23, 'Probe 2 HGA shade', ...
                'FontSize', get(H(1), 'FontSize'), 'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'right', 'tag', 'ShadeAnnotation', 'UserData', 3);
            dcm_obj = datacursormode(get(H(1), 'Parent'));
            set(dcm_obj, 'UpdateFcn', {@lap.datacursor_updatefunction, 'et'})
            grid(H(1), 'on');
            set(H(1), 'layer', 'top')
            %%%
            % Change order of children so that the |Phi|, |Psi| and |Chi| 
            % lines appear _above_ the patch objects (but below the text
            % objects) and |Chi| below the other lines:
            ch = get(H(1), 'Children');  
            set(H(1), 'children', [findobj(ch, 'type', 'line'); ...
                findobj(ch, 'type', 'text'); findobj(ch, 'type', 'patch')]);
            %%%
            % Make timeaxis:
            irf_timeaxis(H(1), irf_time(0, 'tt>epoch'));
            %%%
            % Remove date label from x-axis:
            set(get(H(1), 'xlabel'), 'string', '');
            hold off;
        end
    end

    %%
    % * *Write out illumination conditions*
    if (nargin > 4 && any(cell2mat(cellfun(@(x) ischar(x), varargin, 'uni', false))))
        file_name = varargin{cell2mat(cellfun(@(x) ischar(x), varargin, 'uni', false))};
        %%%
        % Segment into illumination blocks:
        % LAP 1:
        probe = 1;
        lap1_ill_diff = find(diff(lap1_ill));
        ill_blocks1 = [et(1) probe et(lap1_ill_diff(1)), lap1_ill(1), (lap1_ill(1) & floor(lap2_ill(1)))];
        for i = 1:length(lap1_ill_diff)-1
            start = lap1_ill_diff(i)+1;
            stop = lap1_ill_diff(i+1);
            this_block = [et(start) probe et(stop) lap1_ill(start), (lap1_ill(start) & floor(lap2_ill(start)))];
            ill_blocks1 = [ill_blocks1; this_block];
        end
        last_block = [et(lap1_ill_diff(end)) probe et(end) lap1_ill(end), (lap1_ill(end) & floor(lap2_ill(end)))];
        ill_blocks1 = [ill_blocks1; last_block];

        %%%
        % LAP 2:
        probe = 2;
        lap2_ill_diff = find(diff(lap2_ill));
        ill_blocks2 = [et(1) probe et(lap2_ill_diff(1)), lap2_ill(1), (lap1_ill(1) & floor(lap2_ill(1)))];
        for i = 1:length(lap2_ill_diff)-1
            start = lap2_ill_diff(i)+1;
            stop = lap2_ill_diff(i+1);
            this_block = [et(start) probe et(stop) lap2_ill(start), (lap1_ill(start) & floor(lap2_ill(start)))];
            ill_blocks2 = [ill_blocks2; this_block];
        end
        last_block = [et(lap2_ill_diff(end)) probe et(end) lap2_ill(end), (lap1_ill(end) & floor(lap2_ill(end)))];
        ill_blocks2 = [ill_blocks2; last_block];

        %%%
        % Merge LAP1 and LAP2 illumination blocks;
        % Append |ill_blocks2| to |ill_blocks1|:
        ill_blocks = [ill_blocks1; ill_blocks2];

        %%%
        % Sort |ill_blocks| by the start times of the illumination blocks:
        [~, sort_inds] = sortrows(ill_blocks(:,1));
        ill_blocks = ill_blocks(sort_inds,:);

        %%%
        % Print start and stop times of illumination blocks:
%         fid = fopen(file_name, 'wt');
%         for i = 1:size(ill_blocks, 1)
%             switch ill_blocks(i,2)
%                 case 1
%                     if (ill_blocks(i,4))
%                         p1_ill = 'illuminated';
%                     else
%                         p1_ill = '  shaded   ';
%                     end
%                     fprintf(fid, '%s', [cspice_et2utc(ill_blocks(i,1), 'ISOC', 0) ...
%                         ' to ' cspice_et2utc(ill_blocks(i,3), 'ISOC', 0) ' LAP 1 ' p1_ill]);
%                 case 2
%                     if (ill_blocks(i,4) == 1)
%                         p2_ill = 'illuminated';
%                     elseif (ill_blocks(i,4) == 0.4)
%                         p2_ill = 'behind HGA ';
%                     else
%                         p2_ill = 'behind S/C ';
%                     end
%                     fprintf(fid, '%s', [cspice_et2utc(ill_blocks(i,1), 'ISOC', 0) ...
%                         ' to ' cspice_et2utc(ill_blocks(i,3), 'ISOC', 0) ' LAP 2 ' p2_ill]);
%             end
%             %%%
%             % Flag if both probes in sunlight:
%             if (ill_blocks(i,5))
%                 fprintf(fid, '%s', [sprintf('\t') 'Both probes illuminated*' sprintf('\n')]);
%             else
%                 fprintf(fid, '%s', sprintf('\n'));
%             end
%         end


        %%%
        % Old code for printing the illumination blocks of each probe
        % separately:
        % LAP 1:
        %   fid = fopen('Illumination_blocks.txt', 'wt');
        %   for i = 1:size(ill_blocks1, 1)
        %       if (ill_blocks1(i,3))
        %           p1_ill = 'illuminated';
        %       else
        %           p1_ill = '  shaded   ';
        %       end
        %       fprintf(fid, '%s', ['LAP 1 ' p1_ill ' from ' cspice_et2utc(ill_blocks1(i,1), 'ISOC', 3) ...
        %           ' to ' cspice_et2utc(ill_blocks1(i,2), 'ISOC', 3) sprintf('\n')]);
        %   end

        %%%
        % LAP 2:
        %   fprintf(fid, '%s', sprintf('\n'));
        %   for i = 1:size(ill_blocks2, 1)
        %       if (ill_blocks2(i,3) == 1)
        %           p2_ill = 'illuminated';
        %       elseif (ill_blocks2(i,3) == 0.4)
        %           p2_ill = 'behind HGA ';
        %       else
        %           p2_ill = 'behind S/C ';
        %       end
        %       fprintf(fid, '%s', ['LAP 2 ' p2_ill ' from ' cspice_et2utc(ill_blocks2(i,1), 'ISOC', 3) ...
        %           ' to ' cspice_et2utc(ill_blocks2(i,2), 'ISOC', 3)], sprintf('\n'));
        %   end
        
    end
end



%% Unload SPICE kernels
% It is important to unload the kernel files at the end of the program so
% that successive executions won't fill up the kernel pool.
% if ~loaded
%     cspice_unload([kernelFolder '/' kernelFile]);
% end

end

%% Local functions

function [y,grady] = quadobj(x,Q,f,c)
    y = 1/2*x'*Q*x + f'*x + c;
    if nargout > 1
        grady = Q*x + f;
    end
end


function [y,yeq,grady,gradyeq] = quadconstr(x,H,k,d)
    y = 1/2*x'*H*x + k'*x + d;
    yeq = [];
    
    if nargout > 2
        grady = H*x + k;
        gradyeq = [];
    end
end

function [y,yeq,grady,gradyeq] = quadconstr_eq(x,H,k,d)
    y = [];
    yeq = 1/2*x'*H*x + k'*x + d;
    
    if nargout > 2
        grady = [];
        gradyeq = H*x + k;
    end
end


function hess = quadhess(~,lambda,Q,H)
    hess = Q;
    hess = hess + lambda.ineqnonlin*H;
end

function hess = quadhess_eq(~,lambda,Q,H)
    hess = Q;
    hess = hess + lambda.eqnonlin*H;
end






















