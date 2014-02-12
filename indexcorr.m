% Some double check on index creation

tempfilename ='';


for i=1:length(index.t0)
    
    
    flag = 1;
    if (daysact(index(i).t0,index(i).t1)==1) %if start and end time in file is on different days
        %read suspicious file
        trID = fopen(index(i).tabfile,'r');  %read file
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        fclose(trID)
        
       
        primfname = sprintf('/temp/primary_%f',index(i).tabfile(end-29:end));
        primwID = fopen(primfname,'w'); %clear original file
        index(i).tabfile = primfname; %#ok<*SAGROW> %!! 
        %now index stops pointing to original tabfile, and instead points to temporary file
        
        for j=1:length(scantemp{1,3}) %loop all lines of file
            
            t1line = datenum(strrep(scantemp{1,1}{j,1},'T',' ')); %time of suspicious line
            
            if (daysact(index(i).t0, t1line)==0) %if line is same calendar day than t0

                %so this line is okay, print it to same file unchanged.
                %%will this 
                fprintf(primwID,'%s,%f,%f,%f,\n',scantemp{1,1}{j,1},scantemp{1,2}{j},scantemp[1,3}{j},scantemp{1,4}{j});
            else %IF NOT THE SAME DATE
                if (flag==1) %if first item
                    tempfilename = sprintf('/temp/appendix_%d_%d_%f',i,j,index(i).tabfile(end-29:end));   %let's preserve most of the file name   
                    twID = fopen(tempfilename,'w');
                    fclose(twID);
                    flag = 2; % remember to finilize index in later checks
                    
                    
                    % Ugly version of adding a row to index. But I think
                    %this is the best way
                    index(i+1:end+1).lblfile    = index(i:end).lblfile;
                    index(i+1:end+1).tabfile    = index(i:end).tabfile;
                    index(i+1:end+1).t0str      = index(i:end).t0str;
                    index(i+1:end+1).t1str      = index(i:end).t1str;
                    index(i+1:end+1).sct0str    = index(i:end).sct0str;
                    index(i+1:end+1).sct1str    = index(i:end).sct1str;
                    index(i+1:end+1).t0         = index(i:end).t0;
                    index(i+1:end+1).t1         = index(i:end).t1;
                    index(i+1:end+1).macro      = index(i:end).macro;
                    index(i+1:end+1).lf         = index(i:end).lf;
                    index(i+1:end+1).hf         = index(i:end).hf;
                    index(i+1:end+1).sweep      = index(i:end).sweep;
                    index(i+1:end+1).probe      = index(i:end).probe;
                    
                    % adding new information to new 'row'
                    
                    index(i+1).lblfile = 'NA';
                    index(i+1).tabfile = tempfilename;
                    index(i+1).t0str = scantemp{1,1}{j,1};
                    index(i+1).sct0str = scantemp{1,2}{j};
                    index(i+1).t0 = t1line;

                    %keep some information the same as , (commented)
                    %index(i+1).sct1str = [];
                    %index(i+1).macrostr = []; keep it the same
                    %index(i+1).t1str = [];                    
                    %index(i+1).t1 = -1;
                    %index(i+1).macro = -1;
                    %index(i+1).lf = -1;
                    %index(i+1).hf = -1;
                    %index(i+1).sweep = -1;
                    %index(i+1).probe = -1;
                    
                end%if "flag check"
                twID=fopen(tempfilename,'a');
                fprintf(trwID,'%s,%f,%f,%f,\n',scantemp{1,1}{j,1},scantemp{1,2}{j},scantemp[1,3}{j},scantemp{1,4}{j});
                
                fclose(twID); %close temp writefile
                
            end%if "calendar day check"
            
        end%for "read loop"
        

        
        
        if (flag ==2)
         flag =1;   %doesn't need this, flag is set to 1 a few steps later.
        
        index(i+1).t1 = strrep(scantemp{1,1}{j,1},'T',' ');
        index(i+1).t1str= scantemp{1,1}{j,1};
        index(i+1).sct1str =scantemp{1,2}{j};
        
        end%if new file was created
        fclose(primwID)
        clear scantemp
    end%if "file start/end date check"
end%for "loop entire index"


        
%
%                     index(n).lblfile = [];
%                     index(n).tabfile = [];
%                     index(n).t0str = [];
%                     index(n).t1str = [];
%                     index(n).sct0str = [];
%                     index(n).sct1str = [];
%                     index(n).macrostr = [];
%                     index(n).t0 = -1;
%                     index(n).t1 = -1;
%                     index(n).macro = -1;
%                     index(n).lf = -1;
%                     index(n).hf = -1;
%                     index(n).sweep = -1;
%                     index(n).probe = -1;