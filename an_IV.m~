
% analysis



%for i=1:length(tabindex);

%andate = tabindex{:,1}(end-47:end-35);
antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);
andate = str2double(cellfun(@(x) x(8:15),tabindex(:,2),'un',0));

%find(tabindex(:,3=)

%/2010/JUL/D07/RPCLAP_20100707_233243_503_V1H.TAB

%end
%tab_I1H =find(strfind(antype,'I1H'));%strfind(antype,'I2H'));

%ind_I1H= find(strcmp('I1H', antype)|strcmp('I2H', antype));

ind_I1H= find(strcmp('I1H', antype));
ind_I2H= find(strcmp('I2H', antype));
ind_I1L= find(strcmp('I1L', antype));
ind_I2L= find(strcmp('I2L', antype));


ind_V1L= find(strcmp('V1L', antype));
ind_V2L= find(strcmp('V2L', antype));
ind_V1H= find(strcmp('V1H', antype));
ind_V2H= find(strcmp('V2H', antype));




if(~isempty(ind_I1L))
    
    an_daily(ind_I1L,'I',1,'L',tabindex,8)
    an_daily(ind_I1L,'I',1,'L',tabindex,32)
end

if(~isempty(ind_I2L))
    
    an_daily(ind_I2L,'I',2,'L',tabindex,8)
    an_daily(ind_I2L,'I',2,'L',tabindex,32)
end

if(~isempty(ind_V1L))
    
    an_daily(ind_V1L,'V',1,'L',tabindex,8)
    an_daily(ind_V1L,'V',1,'L',tabindex,32)
end

if(~isempty(ind_V2L))
    
    an_daily(ind_V2L,'V',2,'L',tabindex,8)
    an_daily(ind_V2L,'V',2,'L',tabindex,32)
end


if(~isempty(ind_V2H))
    
    an_daily(ind_V2H,'V',2,'H',tabindex,8)
    an_daily(ind_V2H,'V',2,'H',tabindex,32)
end

if(~isempty(ind_V1H))
    
    an_daily(ind_V1H,'V',1,'H',tabindex,8)
    an_daily(ind_V1H,'V',1,'H',tabindex,32)
    
end


if(~isempty(ind_I1H))
    
    an_daily(ind_I1H,'I',1,'H',tabindex,8)
    an_daily(ind_I1H,'I',1,'H',tabindex,32)
    
end
if(~isempty(ind_I2H))
    
    an_daily(ind_I2H,'I',2,'H',tabindex,8)
    an_daily(ind_I2H,'I',2,'H',tabindex,32)
    
end

