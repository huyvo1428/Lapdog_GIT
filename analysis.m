% analysis
% analyses:
% sweeps
% hf spectra -> power spectral density
% downsamples files

t_start_analysis = clock;    % NOTE: Not number of seconds, but [year month day hour minute seconds].

global an_tabindex an_debug;
an_tabindex = zeros(0, 9);
an_debug = 0; %debugging on or off!

antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);



%find datasets of different modes
ind_I1L= find(strcmp('I1L', antype));
ind_I2L= find(strcmp('I2L', antype));
ind_I3L= find(strcmp('I3L', antype));

ind_V1L= find(strcmp('V1L', antype));
ind_V2L= find(strcmp('V2L', antype));
ind_V3L= find(strcmp('V3L', antype));


ind_V1H= find(strcmp('V1H', antype));
ind_V2H= find(strcmp('V2H', antype));
ind_V3H= find(strcmp('V3H', antype));

ind_I1H= find(strcmp('I1H', antype));
ind_I2H= find(strcmp('I2H', antype));
ind_I3H= find(strcmp('I3H', antype));


ind_I1S= find(strcmp('I1S', antype));
ind_I2S= find(strcmp('I2S', antype));



 load_lapdog_runspis=0;
 
 if load_lapdog_runspis
     load(dumplapdog_runspis.mat)
else
     save dump_lapdog_runspis
 end


fprintf(1,'Analysing sweeps\n')

if(~isempty(ind_I1S))
    [XXP]=an_sweepmain_v2(ind_I1S,tabindex,targetfullname);
end 

if(~isempty(ind_I2S))
    fprintf(1,'Skipping Analysing LAP2 sweeps\n')
%    an_sweepmain(ind_I2S,tabindex,targetfullname); 
end





fprintf(1,'Outputting Science\n')
if(~isempty(ind_I1S))
    an_outputscience(XXP)
end 





fprintf(1,'Downsampling low frequency measurements\n')

if(~isempty(ind_I1L))
    %an_downsample(ind_I1L,tabindex,8)
    an_downsample(ind_I1L,32,tabindex,index)
end
 
if(~isempty(ind_I2L))
   % an_downsample(ind_I2L,tabindex,8)
    an_downsample(ind_I2L,32,tabindex,index)
end


ind_VL=[ind_V1L;ind_V2L];

if(~isempty(ind_VL))
    ind_VL=sort(ind_VL,'ascend');
   % an_downsample(ind_V1L,tabindex,8)
    an_downsample(ind_VL,32,tabindex,index)
end

if(~isempty(ind_V1L))
   % an_downsample(ind_V1L,tabindex,8)
%    an_downsample(ind_V1L,32,tabindex,index)
end
 
if(~isempty(ind_V2L))
  %  an_downsample(ind_V2L,tabindex,8)
 %   an_downsample(ind_V2L,32,tabindex,index)
end 



fprintf(1,'Generating spectra\n')
 
if(ind_I1H)        an_hf(ind_I1H,tabindex,'I1H'); end
if(ind_I2H)        an_hf(ind_I2H,tabindex,'I2H'); end
if(ind_I3H)        an_hf(ind_I3H,tabindex,'I3H'); end

if(ind_V1H)        an_hf(ind_V1H,tabindex,'V1H'); end
if(ind_V2H)        an_hf(ind_V2H,tabindex,'V2H'); end
if(ind_V3H)        an_hf(ind_V3H,tabindex,'V3H'); end



fprintf(1, 'Best estimates\n')
%save(['~/temp_MATLAB/temp.', shortphase, '.allVarsBeforeBestEstmimates.', datestr(now,'yyyy-mm-dd_HH.MM.SS'), '.mat'])    % DEBUG
an_tabindex = best_estimates(an_tabindex, tabindex, index, obe);



fprintf(1, '%s (incl. best_estimates): %.0f s (elapsed wall time)\n', mfilename, etime(clock, t_start_analysis));
