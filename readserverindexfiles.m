% scp -r frejon@squid.irfu.se:lapdog/inde* server/
% scp -r frejon@squid.irfu.se:lapdog/tabinde* server/

% rsync -rq frejon@squid.irfu.se:/data/LAP_ARCHIVE/RO-C-RPCLAP-3-M07* /Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/
% rsync -rq frejon@squid.irfu.se:/data/LAP_ARCHIVE/RO-C-RPCLAP-5-M07* /Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/


%load index files


s_tabindexfile = sprintf('server/tabindex/tabindex_%s.mat',archiveid);
fp = fopen(s_tabindexfile,'r');
%fp = -2;

if(fp > 0)
    fclose(fp);
    load(s_tabindexfile);
    'lapdog: succesfully loaded server tabindex'
    
end

substring = strrep(tabindex(1,1),tabindex(1,2),'');

%substring = 'ajskldjalskd/2014/MMM/DDD/'
tabindexsubstring= substring(1:end-42);

%indexsubstring=substring(1:end-14);

newstring= '/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/';



indexcol1 = cellfun(@(x) strrep(x,tabindexsubstring,newstring),tabindex(:,1),'un',0);




%/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-C-RPCLAP-5-M07-DERIV-V0.1/2014/SEP/D01/RPCLAP_20140901_235824_506_B1S.TAB
%tabindex has format:
%{ ,1} filename
%{ ,2} shortfilename
%{ ,3} first index number
%{ ,4} end time(UTC)
%{ ,5} end time (S/C clock)
%{ ,6} number of columns
%{ ,7} number of rows


% 
% 
% 
% s_indexfile = sprintf('server/index/index_%s.mat',archiveid);
% fp = fopen(s_indexfile,'r');
% 
% if(fp > 0)
%     fclose(fp);
%     load(s_indexfile);
%     'lapdog: succesfully loaded server index'
% end




% %andate = tabindex{:,1}(end-47:end-35);
% antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);
% andate = str2double(cellfun(@(x) x(8:15),tabindex(:,2),'un',0));

%scantemp(:,3)= cellfun(scantemp(:,4)=cellfun(@(x) x+CURRENTO2,scantemp(:,4),'un',0);