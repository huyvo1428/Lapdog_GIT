%function I_filtered = sweepFilterChooser(I,dv)
%
%Description: Handles the logic for choosing a good filter to use for LAP
%IV sweeps. Also caches the results so in a persistent function memory so  
%that the CPU heavy filter function gets called fewer times.
%
%since an_LP_Sweep and an_LP_Sweep_with_assmpt are called after eachother,
%I_cache == I 50% of the calls
%
%
% % we have three or four cases for filtering:
% dv = 0.25 --> e.g. 604, 807 (probably burst mode)
% dv = 0.5  --> e.g. 506
% dv = 0.75 --> e.g. 505
% dv = 1    --> e.g  212 (rare)
% dv << 0.25 --> fine sweeps, (not implemented yet)
%
function I_filtered = sweepFilterChooser(I,dv)

persistent I_cache
persistent I_filtered_cache
% persistent i
% persistent i2
% 
% if isempty(i)
%     i = 0;
%     i2 = 0;
% 
% end
% if ~isempty(I_cache)  
%     figure(7)
%     plot(1:length(I),I,'bo',1:length(I_cache),I_filtered_cache,'r',1:length(I_cache),I_cache,'b+');
%     title(sprintf('%i calls %i duplicates)',i,i2));
% end
% i = i +1;

%checks if the vectors are equal (I_cache is initialised as empty matrix by
%'persistent' variable declaration)
if isequalwithequalnans(I_cache,I)
    I_filtered = I_filtered_cache;
  % i2 = i2 + 1;    
    return
end
% tic
% ~isempty(I_cache) && floor(mean(I_cache == I)+0.5)  
% toc
% tic
% isequaln(I_cache,I) 
% toc
% tic
% isequalwithequalnans(I_cache,I)     <--- winner. even though matlab
% complains
% toc
if dv < 0.27 %i.e. if dv ~ 0.25
    
    sSpan = ceil(0.1*length(I));  % loose rloess filter
    sSpan = max(sSpan,6);  %HORRIBLE BUG IF SPAN == 5!!! (or 4)
  %  sSpan = 0.1001;
    sMethod = 'rloess';   % loose rloess filter
elseif dv > 0.72
    
    sSpan = ceil(0.2*length(I));
    %sSpan = 0.2;     %pretty heavy sgolay filter.
    sMethod = 'sgolay';
else  %i.e. if dv ~ 0.5
    
    sSpan = ceil(0.1*length(I));  % loose rloess filter
    sSpan =max(sSpan,6);  %HORRIBLE BUG IF SPAN == 5!!! (or 4)
    
  %  sSpan = 0.1001;        % loose rloess filter
    sMethod = 'rloess';
end
        
    I_filtered = smooth(I,sSpan,sMethod,1).'; %filter sweep NB transpose
    I_filtered_cache = I_filtered;
    I_cache = I;
    
    
    


end

