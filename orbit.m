%% ORBIT Plot orbit trajectory
% orbit(object, time, origin, frame) plots the trajectory of _object_
% (string) during the time interval specified by _time_ (1x2 cell array of
% strings or 2x1 array of double precision values) w.r.t. _origin_ (string)
% in the reference frame specified by _frame_ (string). The plot is in 3D.
%
% If time contains more than two epochs, these are used as sample times
% rather than start/stop times.
%
% If an output argument is supplied, a 6xN matrix is given containing the
% six position and velocity components in spherical coordinates for each
% of the N sample times between the start and stop time specified in the
% time input argument.
%
% If two output arguments are supplied, a 3x3xN set of rotation matrices 
% that transforms the components of a vector expressed in the frame 
% specified by 'frame' to components expressed in the frame tied to the 
% object is given as the second output. This represents the orientation/
% attitude of the object.
%
% If three output arguments are supplied, the third is the 1xN row vector
% of solar aspect angles (w.r.t the object z-axis).
%   
% Available frames are any frames natively recognized by SPICE. Or 'IAU',
% specifying the body-fixed (rotating) frame cenetered on origin. Or
% 'Terminal', specifying a frame centered on origin with the x-axis
% pointing towards the Sun (the z-axis is the orthogonal projection of
% the IAU z-axis w.r.t the x-axis).
%   
% If time contains more than one epoch, a 2D plot of object's altitude and
% latitude is produced, in addition to the 3D trajectory plot. (OBS! The
% latitude values depend on the frame of reference chosen!)
%
% If time consists of floating point number(s), these are interpreted as 
% representing the number of TDB seconds past the J2000 epoch, i.e.
% Ephemeris Time (ET). Alternatively, epochs may be supplied in the form
% of a cell array containing string(s) in any format recognized by SPICE
% as epochs. (E.g. the ISOC calendar format: YYYY-MM-DDThh:mm:ss.sss)

function [varargout] = orbit(object, time, origin, frame)

%% Set up paths and SPICE kernel files
% PATHS() gives paths to SPICE kernels directory and sets up MICE paths.

paths();

%% Load SPICE kernel files
% The SPICE kernel files ahve to be loaded in order to be accessible from
% MICE, this is done by the the function CSPICE_FURNSH. For convenience,
% the full list of kernels to load is stored in an external .txt file so
% that calling CSPICE_FURNSH for this file loads all the kernels at once.
% OBS! This metakernel textfile contains the absolute search paths to the
% SPICE kernels and must therefore be configured specifically for the local
% machine!

dynampath = strrep(mfilename('fullpath'),'/orbit','');
% 

% p = strrep(p,p{1,1},dynampath);


kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
cspice_furnsh(kernelFile);

%% Read input
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
    dt = (t(2)-t(1))/10000;
    et = t(1):dt:t(2);
else
    et = t;
end

%%%
% Get name of reference frame:
if (strcmpi(frame, 'IAU') || strcmpi(frame, 'Terminal'))
    ref = [frame '_' origin];
else
    ref = frame;
end

%%%
% Get reference body radius for normalization purposes:
radii = cspice_bodvrd(origin, 'RADII', 3);
R_0 = radii(1);

%% Get SPICE orbit data
% Compute orbit states:
state = cspice_spkezr(object, et, ref, 'LT+S', origin);

%%%
% Convert to spherical coordinates:
r = @(x) sqrt(sum(x.^2,1));
theta = @(x) acos(x(3,:)./r(x));
phi = @(x) atan(x(2,:)./x(1,:));
S = @(x) [r(x); theta(x); phi(x)];
state_s = [S(state(1:3,:)); S(state(4:6,:))];

%%%
% Compute altitude and latitude:
altitude = state_s(1,:)'-R_0;
latitude = 90-180/pi*state_s(2,:)';

%%%
% Find direction of the sun:
sun = cspice_spkpos('Sun', et, ref, 'LT+S', origin);
sun_s = S(sun);
sun_n = sun/sun_s(1)*R_0; % normalization

%% Get SPICE S/C orientation
% Get object NAIF ID code:
id = cspice_bodn2c(object);

%%%
% Convert to corresponding structure id:
id_str = id*1000;

%%%
% Convert epochs to (continuous) spacecraft clock counts:
et_s = cspice_sce2c(id, et);

%%%
% Get change of basis transformation matrix:
[cmat, clkout, found] = cspice_ckgp(id_str, et_s, 0, ref);

%%%
% Compute the inverse of the change of basis transformatation matrix (the 
% COLUMNS of which are the the basis vectors of the S/C frame expressed in
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
basis_n = basis*R_0;

%%%
% Find direction of the sun in S/C frame:
sun_sc = cspice_spkpos('Sun', et, 'ROS_SPACECRAFT', 'LT+S', object);
sun_sc_s = S(sun_sc);
% sun_sc_n = sun_sc/sun_sc_s(1)*R_0; % normalization

%%%
% Solar aspect angle (w.r.t z-axis in S/C frame, '+' above y-z plane, '-' below)
Phi = sun_sc_s(2,:)*180/pi.*sign(pi-sun_sc_s(3,:));

%% Find RPC-LAP illumination conditions
% This is only done when _object_ is Rosetta:
if (id == -226 || id == -226000)
    
    %%% 
    % *Currently unused code for finding illumination boundary angles for
    % arbitrary solar array orientation (though still assumed perpendicular
    % to the Sun):*
    
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
    Phi11 = 131;
    Phi12 = 181;
    lap1_ill = ((Phi < Phi11) | (Phi > Phi12));
    
    %%%
    % Alternative obtainment of illumination logical (for arbitrary SA
    % orientation, though still perpendicular to the Sun):
    %
    %   lap1_ill = (abs(lap1_pos_SA1(1,:)) > SA_HW);
    
    %%%
    % Probe 2 (c.f. lap2geo.pdf):
    %
    %   Phi21 = 23.5;
    %   Phi22 = 79.6;
    %   Phi23 = 109.3;

    %%%
    % *Anders values* (+90 degrees)
    Phi21 = 18;
    Phi22 = 82;
    Phi23 = 107;
    lap2_ill = ((Phi < Phi21) | (Phi > Phi22)) - 0.6*((Phi > Phi22) & (Phi < Phi23));

end

%% Plotting
% If no output argument is provided, give results in the form of plots.

if (nargout == 0)
    %%
    % * *Plot 3D*
    figure('Position', [0 930 640 480])
    
    %%%
    % Draw sphere: (redundant)
    %
    %   [X, Y, Z] = sphere(20);
    
    %%%
    % Draw ellipsoid:
    [X, Y, Z] = ellipsoid(0, 0, 0, radii(1)/R_0, radii(2)/R_0, radii(3)/R_0, 20);
    colormap gray;
    h = surf(R_0*X,R_0*Y,R_0*Z, 'CDataMapping', 'direct', 'FaceColor', 'interp');
    set(gca, 'FontSize', 14);
    hAnnotation = get(h, 'Annotation');
    hLegendEntry = get(hAnnotation, 'LegendInformation');
    set(hLegendEntry, 'IconDisplayStyle', 'off');
    hold;
    
    %%%
    % Plot direction to Sun:
    if (length(et) == 1 || strcmpi(frame, 'terminal') || strcmpi(frame, 'J2000') ...
            || strcmpi(frame, 'ECLIPJ2000'))
        quiver3(1.1*sun_n(1), 1.1*sun_n(2), 1.1*sun_n(3), sun_n(1), sun_n(2), sun_n(3), ...
            'r', 'LineWidth', 2, 'DisplayName', 'Sun');
        C = 24 + 32*ones(size(Z)).*(X*sun_n(1) + Y*sun_n(2) + Z*sun_n(3) > 0);
        set(h, 'CData', C);
    end

    %%%
    % Plot trajectory and orientation of object:
    a = state(1,:);
    b = state(2,:);
    c = state(3,:);
    if (length(et) == 1)
        %%%
        % Draw position vector:
        quiver3(0, 0, 0, a, b, c, 0, 'k', 'LineWidth', 1.2, 'DisplayName', ...
            [object ' position vector']);
        %%%
        % Draw orientation in the form of S/C frame basis vectors
        quiver3(a, b, c, basis_n(1,1,1), basis_n(2,1,1), basis_n(3,1,1), ...
            'g', 'LineWidth', 1.2, 'DisplayName', ['x ' object ' S/C frame']);
        quiver3(a, b, c, basis_n(1,2,1), basis_n(2,2,1), basis_n(3,2,1), ...
            'm', 'LineWidth', 1.2, 'DisplayName', ['y ' object ' S/C frame']);
        quiver3(a, b, c, basis_n(1,3,1), basis_n(2,3,1), basis_n(3,3,1), ...
            'b', 'LineWidth', 1.2, 'DisplayName', ['z ' object ' S/C frame']);
        scatter3(a, b, c, 'k', 'filled', 'DisplayName', object);
        axis(min(max(state_s(1,:)), 10*R_0)*[-1 1 -1 1 -1 1])
    else
        if (strcmpi(frame, 'terminal') == 0 && strcmpi(frame, 'J2000') == 0 && ...
                strcmpi(frame, 'ECLIPJ2000') == 0)
            set(h, 'FaceColor', [0.7 0.7 0.7]);
        end
        %%%
        % Trajectory:
        plot3(a, b, c, 'k', 'LineWidth', 1.2, 'DisplayName', [object ' trajectory']);
        %%%
        % Orientation:
        Q_scale = 0.05;
        Q_step = 10;
        quiver3(a(1:Q_step:end), b(1:Q_step:end), c(1:Q_step:end), ...
            squeeze(basis_n(1,1,1:Q_step:end))', squeeze(basis_n(2,1,1:Q_step:end))', ...
            squeeze(basis_n(3,1,1:Q_step:end))', Q_scale, 'g', 'DisplayName', ['x ' object ' S/C frame'])
        quiver3(a(1:Q_step:end), b(1:Q_step:end), c(1:Q_step:end), ...
            squeeze(basis_n(1,2,1:Q_step:end))', squeeze(basis_n(2,2,1:Q_step:end))', ...
            squeeze(basis_n(3,2,1:Q_step:end))', Q_scale, 'm', 'DisplayName', ['y ' object ' S/C frame'])
        quiver3(a(1:Q_step:end), b(1:Q_step:end), c(1:Q_step:end), ...
            squeeze(basis_n(1,3,1:Q_step:end))', squeeze(basis_n(2,3,1:Q_step:end))', ...
            squeeze(basis_n(3,3,1:Q_step:end))', Q_scale, 'b', 'DisplayName', ['z ' object ' S/C frame'])
        axis(max(state_s(1,:))*[-1 1 -1 1 -1 1]);
    end
    l = legend('Location', 'NorthEast');
    set(l, 'box', 'off', 'color', 'none');
    hold off;

    %%
    % * *Plot altitude and latitude*
    if(length(et) > 1)    
        figure('Position', [640 930 640 480])
        h = irf_plot(1);
        irf_plot(h(1), [irf_time(et,'et2epoch')'  altitude], 'k', 'LineWidth', 2);
        set(h(1), 'FontSize', 18);
        set(get(gca, 'XLabel'), 'FontSize', get(h(1), 'FontSize'));
        ylabel('Altitude (km)', 'FontSize', get(h(1), 'FontSize'));
        limY = ylim;
        axis tight;
        ylim(limY);

        h(2) = axes('Position',get(h(1),'Position'));
        irf_plot(h(2), [irf_time(et,'et2epoch')' latitude], 'r', 'LineWidth', 2);
        set(h(2), 'FontSize', get(h(1), 'FontSize'), 'YAxisLocation', 'right', 'Color', 'none', 'box', ...
            'off', 'YColor', 'r');
        set(get(gca, 'XLabel'), 'FontSize', get(h(2), 'FontSize'));
        ylabel('Latitude (\circ)', 'FontSize', get(h(2), 'FontSize'));
        limY = ylim;
        axis tight;
        ylim(limY);
    end

    %%
    % * *Plot solar ascpect angle (for Rosetta)*
    if (id == -226 || id == -226000)
        figure('Position', [1280 930 640 480])
        H = irf_plot(1);
        irf_plot(H(1), [irf_time(et,'et2epoch')'  Phi'], 'k', 'LineWidth', 2);
        set(H(1), 'FontSize', 18);
        set(get(H(1), 'XLabel'), 'FontSize', get(H(1), 'FontSize'));
        ylabel('Solar aspect angle (\circ)', 'FontSize', get(H(1), 'FontSize'));
        axis tight;
        xl = xlim;
        ylim([0 180]);
        colour = [0.4 0.4 0.4];
        alpha = 0.5;
        hold;
        patch([xl(1) xl(1) xl(2) xl(2)], [Phi11 Phi12 Phi12 Phi11], colour, ...
            'FaceAlpha', alpha, 'EdgeColor', colour, 'EdgeAlpha', alpha)
        patch([xl(1) xl(1) xl(2) xl(2)], [Phi21 Phi22 Phi22 Phi21], colour, ...
            'FaceAlpha', alpha, 'EdgeColor', colour, 'EdgeAlpha', alpha)
        patch([xl(1) xl(1) xl(2) xl(2)], [Phi22 Phi23 Phi23 Phi22], 1-colour, ...
            'FaceAlpha', alpha, 'EdgeColor', 1-colour, 'EdgeAlpha', alpha)    
        text(xl(2), Phi12, 'Probe 1 shaded', ...
            'FontSize', get(H(1), 'FontSize'), 'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'right');
        text(xl(2), Phi21, 'Probe 2 shaded', ...
            'FontSize', get(H(1), 'FontSize'), 'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'right');
        text(xl(2), Phi23, 'Probe 2 HGA shade', ...
            'FontSize', get(H(1), 'FontSize'), 'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'right');
    end

%% Output
% Several output formats are possible depending on the number of output
% arguments given.
elseif (nargout == 1)
    varargout = {altitude};
elseif (nargout == 2)
    varargout = {altitude, latitude};
elseif (nargout == 3)
    varargout = {altitude, latitude, Phi};
elseif (nargout == 4)
    varargout = {altitude, latitude, Phi, et};
end

%% Unload SPICE kernels
% It is important to unload the kernel files at the end of the program so
% that successive executions won't fill up the kernel pool.
cspice_unload(kernelFile);

end































