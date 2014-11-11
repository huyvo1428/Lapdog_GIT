% analysis
% analyses:
% sweeps
% hf spectra -> power spectral density
% downsamples files



global an_tabindex;
an_tabindex = [];

antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);
andate = str2double(cellfun(@(x) x(8:15),tabindex(:,2),'un',0));


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







fprintf(1,'Analysing sweeps\n')



   


if(~isempty(ind_I1S))

an_sweepmain(ind_I1S,tabindex,targetfullname);


end





if(~isempty(ind_I2S))
an_sweepmain(ind_I2S,tabindex,targetfullname);

end





fprintf(1,'Downsample Low frequency measurements \n')

   

%send mode datatasets to downsampler function

% 
% if(~isempty(ind_I1L))
%     %an_downsample(ind_I1L,tabindex,8)
%     an_downsample(ind_I1L,tabindex,32)
% end
% 
% if(~isempty(ind_I2L))
% 
%    % an_downsample(ind_I2L,tabindex,8)
%     an_downsample(ind_I2L,tabindex,32)
% end
% 
% 
% 
% 
% if(~isempty(ind_V1L))
% 
%    % an_downsample(ind_V1L,tabindex,8)
%     an_downsample(ind_V1L,tabindex,32)
% end
% 
% if(~isempty(ind_V2L))
% 
%   %  an_downsample(ind_V2L,tabindex,8)
%     an_downsample(ind_V2L,tabindex,32)
% end
% 
% 

%  Mill the HF data in this ob:
    


fprintf(1,'Generating Spectra\n')
% 
% if(ind_I1H)        an_hf(ind_I1H,tabindex,'I1H'); end
% if(ind_V1H)        an_hf(ind_V1H,tabindex,'V1H'); end
% if(ind_V2H)        an_hf(ind_V2H,tabindex,'V2H'); end
% if(ind_V3H)        an_hf(ind_V3H,tabindex,'V3H'); end
% 
% 
% if(ind_I2H)        an_hf(ind_I2H,tabindex,'I2H'); end
% if(ind_I3H)        an_hf(ind_I3H,tabindex,'I3H'); end
% 
% 
% 
% 











