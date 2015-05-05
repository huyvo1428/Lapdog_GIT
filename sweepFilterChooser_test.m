%function I_filtered = sweepFilterChooser_test(I,dv)
%
%Description: Handles the logic for choosing a good filter to use for LAP
%IV sweeps. Also caches the results so in a persistent function memory so  
%that the CPU heavy filter function gets called fewer times.
%
% % we have three or four cases for filtering:
% dv = 0.25 --> e.g. 604, 807 (probably burst mode)
% dv = 0.5  --> e.g. 506
% dv = 0.75 --> e.g. 505
% dv = 1    --> e.g  212 (rare)
% dv << 0.25 --> fine sweeps, (not implemented yet)
%
function I_filtered = sweepFilterChooser_test(I,dv)


persistent i

if dv < 0.27 %i.e. if dv ~ 0.25
    
    sSpan = ceil(0.1*length(I));  % loose rloess filter
    sSpan = max(sSpan,6);  %HORRIBLE BUG IF SPAN == 5!!! (or 4)
  %  sSpan = 0.1001;
    sMethod = 'loess';   % loose rloess filter
elseif dv > 0.72
    
    sSpan = ceil(0.2*length(I));
    %sSpan = 0.2;     %pretty heavy sgolay filter.
    sMethod = 'sgolay';
else  %i.e. if dv ~ 0.5
    
    sSpan = ceil(0.1*length(I));  % loose rloess filter
    sSpan =max(sSpan,6);  %HORRIBLE BUG IF SPAN == 5!!! (or 4)
    
  %  sSpan = 0.1001;        % loose loess filter
    sMethod = 'loess';
end
        
    I_filtered = smooth(I,sSpan,sMethod,1).'; %filter sweep NB transpose
    Rsq = 1 - nansum(((I-I_filtered).^2))/nansum(((I-nanmean(I)).^2));
    
%     
%     V=1:length(I);
%     figure(1)
%     tic
%     a = smooth(I,sSpan,'rloess',1).';
%     toc
%     tic
%     b = smooth(I,sSpan,'loess',1).';
%     toc
%     
%     plot(V,I,'black+',V,b,'bo',V,a,'ro');
%     
%     
    
 %   Rsq
 
 if Rsq < 0.95 % inexplicable horrible performance for certain super smooth sweeps.
     
     if isempty(i)
         i = 0;
     end     
     i=i+1;
     if mod(i,100) == 1
         fprintf(1,'%i bad smoothening performance\n',i);
     end
     
     
     I_filtered = smooth(I,'rloess',1).';
     Rsq = 1 - nansum(((I-I_filtered).^2))/nansum(((I-nanmean(I)).^2));
     
     if Rsq < 0.95         
         
         i = i+10000;
         
         I_filtered = I;
 
         
     end
 end 
end

