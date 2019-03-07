% analysis
% analyses:
% sweeps
% hf spectra -> power spectral density
% downsamples files

t_start_analysis = clock;    % NOTE: Not number of seconds, but [year month day hour minute seconds].

global an_tabindex an_debug;
an_tabindex = zeros(0, 9);
an_debug = 0; %debugging on or off!
global usc_tabindex;
usc_tabindex=[];
antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);

XXP =[];
XXP2=[];
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


spath=sprintf('%s/XXP_save_v2.mat',derivedpath);
%
% try
%
% load(spath,'XXP')
% fprintf(1,'load XXP successful')
%
% catch err

fprintf(1,'Analysing sweeps\n')

if(~isempty(ind_I1S))
    [XXP]=an_sweepmain_v2(ind_I1S,tabindex,targetfullname);
end
save(spath,'XXP');

if(~isempty(ind_I2S))
    fprintf(1,' Analysing LAP2 sweeps\n')
    [XXP2]=an_sweepmain_v2(ind_I2S,tabindex,targetfullname);
    save(spath,'XXP','XXP2');
end







fprintf(1,'Outputting Science\n')
if(~isempty(XXP))
    an_outputscience(XXP);


else
    fprintf(1,'Error: an empty XXP was loaded, or no sweeps were analysed. aborting\n')
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



try
    if ~isempty(usc_tabindex)  % some USC (Vz) files might be overwritten by our routine, and creates duplicate entries in usc_tabindex. We should find these and delete them
        usc_tabindex(:).fname
        [Uniquefname,junk,k] = unique({usc_tabindex(:).fname});
        % Uniquefname is a sorted list of usc_tabindex.fname
        % k is indices of uniqueC that represents usc_tabindex.fname, some of them might be
        % duplicates
        N_Uniquefname = histc(k,1:numel(Uniquefname)); %
        % N > 1 corresponds to indices of duplicates in the sorted list
        % uniqueC
        if any(N_Uniquefname>1)
            fprintf(1,'Deleting duplicates in USC_TABINDEX \n')
            vz_inds= strcmp('Vz',{usc_tabindex.type});
            dupindz= find(N_Uniquefname>1);
            delindz=[];
            for i=1:length(dupindz)

                checkindz=strcmp(Uniquefname(dupindz(i)),{usc_tabindex.fname}); %this should only find two files, but it works for more.
                delthis= find(checkindz & vz_inds); %all duplicates that are also Vz files should be deleted. (this should keep the Vfloat files)
                %delthis= find(strcmp(usc_tabindex(checkindz).type,'Vz')); %all duplicates that are also Vz files should be deleted. (this should keep the Vfloat files)

                delindz=[delindz;checkindz(delthis)];%append to list of deletion indices

            end
            usc_tabindex(delindz)=[];
            %loop finished, make deletion

        end




    end

catch err
    fprintf(1,'Error: Deleting of duplicate USC_TABINDEX failed \n')
    err.identifier
    err.message
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i; ',err.stack(i).name,err.stack(i).line);
        end
    end

end


%fprintf(1, 'Best estimates\n')
%an_tabindex = best_estimates(an_tabindex, tabindex, index, obe);



%fprintf(1, '%s (incl. best_estimates): %.0f s (elapsed wall time)\n', mfilename, etime(clock, t_start_analysis));
