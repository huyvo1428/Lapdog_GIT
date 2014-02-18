
% analysis


global an_tabindex;


%for i=1:length(tabindex);

%andate = tabindex{:,1}(end-47:end-35);
antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);
andate = str2double(cellfun(@(x) x(8:15),tabindex(:,2),'un',0));

%end
%tab_I1H =find(strfind(antype,'I1H'));%strfind(antype,'I2H'));

%ind_I1H= find(strcmp('I1H', antype)|strcmp('I2H', antype));



%find datasets of different modes
ind_I1H= find(strcmp('I1H', antype));
ind_I2H= find(strcmp('I2H', antype));
ind_I1L= find(strcmp('I1L', antype));
ind_I2L= find(strcmp('I2L', antype));


ind_V1L= find(strcmp('V1L', antype));
ind_V2L= find(strcmp('V2L', antype));
ind_V1H= find(strcmp('V1H', antype));
ind_V2H= find(strcmp('V2H', antype));


%send mode datatasets to downsampler function
if(~isempty(ind_I1L))
    an_downsample(ind_I1L,tabindex,8)
    an_downsample(ind_I1L,tabindex,32)
end

if(~isempty(ind_I2L))
    
    an_downsample(ind_I2L,tabindex,8)
    an_downsample(ind_I2L,tabindex,32)
end

if(~isempty(ind_V1L))
    
    an_downsample(ind_V1L,tabindex,8)
    an_downsample(ind_V1L,tabindex,32)
end

if(~isempty(ind_V2L))
    
    an_downsample(ind_V2L,tabindex,8)
    an_downsample(ind_V2L,tabindex,32)
end


if(~isempty(ind_V2H))
    
    an_downsample(ind_V2H,tabindex,8)
    an_downsample(ind_V2H,tabindex,32)
end

if(~isempty(ind_V1H))
    
    an_downsample(ind_V1H,tabindex,8)
    an_downsample(ind_V1H,tabindex,32)
    
end


if(~isempty(ind_I1H))
    
    an_downsample(ind_I1H,tabindex,8)
    an_downsample(ind_I1H,tabindex,32)
    
end
if(~isempty(ind_I2H))
    
    an_downsample(ind_I2H,tabindex,8)
    an_downsample(ind_I2H,tabindex,32)
    
end

