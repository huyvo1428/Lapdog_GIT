% Some doublecheck on index creation

count = 0;

%check very specific bug where index(end) is retarded



lindex = length(index);


mkdir(sprintf('%s/temp',archivepath))

for i=1:length(index)
    
    
    flag = 1;
    
    
    %if start and end time in file is on different days
    %Exception: if file is a sweep file, then don't separate files!
    if (strcmp(datestr(index(i).t0,'yymmdd'),datestr(index(i).t1,'yymmdd'))==0 && index(i).sweep ==0)
        %if (daysact(index(i).t0,index(i).t1)==1) %if start and end time in file is on different days
        %read suspicious file
        trID = fopen(index(i).tabfile,'r');  %read file
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        fclose(trID);
        

        primfname = sprintf('%s/temp/primary_%s',archivepath,index(i).tabfile(end-28:end));
        primwID = fopen(primfname,'w'); %clear original file
        index(i).tabfile = primfname; %#ok<*SAGROW> %!! 
        %now index stops pointing to original tabfile, and instead points to temporary file
        
        for j=1:length(scantemp{1,3}) %loop all lines of file
            
            t1line = datenum(strrep(scantemp{1,1}{j,1},'T',' ')); %time of suspicious line
            
   %         if (daysact(index(i).t0, t1line)==0)
             if (strcmp(datestr(index(i).t0,'yymmdd'),datestr(t1line,'yymmdd'))==1) %if line is same calendar day than t0

                %so this line is okay, print it to same file unchanged.
                %%will this 
                fprintf(primwID,'%s,%16.6f,%14.7e,%14.7e\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            else %IF NOT THE SAME DATE
                if (flag==1) %if first item
                    tempfilename = sprintf('%s/temp/appendix_%i_%i_%s',archivepath,i,j,index(i).tabfile(end-28:end));   %let's preserve most of the file name   
                    twID = fopen(tempfilename,'w');
                    fclose(twID);
                    flag = 2; % remember to finilize index in later checks
                    
                    index(end+1) = index(i); %copy result to new index
                    
         %%           
                    % SUPER Ugly version of adding a row to index. But I
                    % can't find a better way
% 
%                     %tic
%                     a= index(i:end);
%                     index(i+1:end+1)=a;
%                     clear a
%                    % toc
%                    
%                    [scrap,order] =sort([index(:).t0,'ascend');
%                    sortedindex =index(order);
%                    
%                     
                    
%                     
%                     k = length(index);
%                     tic          
%                     while le(i,k)
%                                        
%                         index(k+1).lblfile    = index(k).lblfile;
%                         index(k+1).tabfile    = index(k).tabfile;
%                         index(k+1).t0str      = index(k).t0str;
%                         index(k+1).t1str      = index(k).t1str;
%                         index(k+1).sct0str    = index(k).sct0str;
%                         index(k+1).sct1str    = index(k).sct1str;
%                         index(k+1).macrostr   = index(k).macrostr;
%                         index(k+1).t0         = index(k).t0;
%                         index(k+1).t1         = index(k).t1;
%                         index(k+1).macro      = index(k).macro;
%                         index(k+1).lf         = index(k).lf;
%                         index(k+1).hf         = index(k).hf;
%                         index(k+1).sweep      = index(k).sweep;
%                         index(k+1).efield     = index(k).efield;
%                         index(k+1).probe      = index(k).probe;
%                         k= k -1;
%                         
%                     end%while index loop
%                     clear k;
%                     toc

                        
                    % Ugly version of adding a row to index. But I think
                    %this is the only way
                    % apparantly not, this doesnt work!
                    
%                     [index(i+1:end+1).lblfile]    = index(i:end).lblfile;
%                     [index(i+1:end+1).tabfile]    = index(i:end).tabfile;
%                     [index(i+1:end+1).t0str]      = index(i:end).t0str;
%                     [index(i+1:end+1).t1str]      = index(i:end).t1str;
%                     [index(i+1:end+1).sct0str]    = index(i:end).sct0str;
%                     [index(i+1:end+1).sct1str]    = index(i:end).sct1str;
%                     [index(i+1:end+1).macrostr]   = index(i:end).macrostr;
%                     [index(i+1:end+1).t0]         = index(i:end).t0;
%                     [index(i+1:end+1).t1]         = index(i:end).t1;
%                     [index(i+1:end+1).macro]      = index(i:end).macro;
%                     [index(i+1:end+1).lf]         = index(i:end).lf;
%                     [index(i+1:end+1).hf]         = index(i:end).hf;
%                     [index(i+1:end+1).sweep]      = index(i:end).sweep;
%                     [index(i+1:end+1).efield]     = index(i:end).efield;
%                     [index(i+1:end+1).probe]      = index(i:end).probe;
%                     
%                     
% %  
%                     [index(i+1:end+1).lblfile]    = [index(i:end).lblfile];
%                     [index(i+1:end+1).tabfile]    = [index(i:end).tabfile];
%                     [index(i+1:end+1).t0str]      = [index(i:end).t0str];
%                     [index(i+1:end+1).t1str]      = [index(i:end).t1str];
%                     [index(i+1:end+1).sct0str]    = [index(i:end).sct0str];
%                     [index(i+1:end+1).sct1str]    = [index(i:end).sct1str];
%                     [index(i+1:end+1).macrostr]   = [index(i:end).macrostr];
%                     [index(i+1:end+1).t0]         = [index(i:end).t0];
%                     [index(i+1:end+1).t1]         = [index(i:end).t1];
%                     [index(i+1:end+1).macro]      = [index(i:end).macro];
%                     [index(i+1:end+1).lf]         = [index(i:end).lf];
%                     [index(i+1:end+1).hf]         = [index(i:end).hf];
%                     [index(i+1:end+1).sweep]      = [index(i:end).sweep];
%                     [index(i+1:end+1).efield]     = [index(i:end).efield];
%                     [index(i+1:end+1).probe]      = [index(i:end).probe];
%                     
%          
             %%       
             
                      %  index(end+1).tabfile=
                    
                    % adding new information to NEW INDEX ENTRY i+1
                    % All entries dont need to be updated, inherited from
                    % old index
                    
                    %index(i+1).lblfile = 'NA'; Creates a problem in LBL
                    %genesis
%                                         %genesis
%                     index(i+1).tabfile = tempfilename;
%                     index(i+1).t0str = scantemp{1,1}{j,1};
%                     index(i+1).sct0str = scantemp{1,2}(j);
%                     index(i+1).t0 = t1line;
% 
%                     % adding new end time information to OLD INDEX ENTRY i
%                     
%                     index(i).t1str = scantemp{1,1}{j-1,1};
%                     index(i).t1 = datenum(strrep(scantemp{1,1}{j-1,1},'T',' '));
%                     index(i).sct0str = scantemp{1,2}(j-1);
                    
                    
                    index(end).tabfile = tempfilename;
                    index(end).t0str = scantemp{1,1}{j,1};
                    index(end).sct0str = scantemp{1,2}(j);
                    index(end).t0 = t1line;

                    % adding new end time information to OLD INDEX ENTRY i
                    
                    index(i).t1str = scantemp{1,1}{j-1,1};
                    index(i).t1 = datenum(strrep(scantemp{1,1}{j-1,1},'T',' '));
                    index(i).sct0str = scantemp{1,2}(j-1);
                    %keep some information the same as , (commented)
 
                    
                end%if "flag check"
                twID=fopen(tempfilename,'a');
                fprintf(twID,'%s,%16.6f,%14.7e,%14.7e\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                
                fclose(twID); %close temp writefile
                
            end%if "calendar day check"
            
        end%for "read loop"
        

        
        
        if (flag ==2)
         flag =1;   %doesn't need this, flag is set to 1 a few steps later.
        count = count +1
        i
        index(end).t1 = datenum(strrep(scantemp{1,1}{j,1},'T',' '));
        index(end).t1str= scantemp{1,1}{j,1};
        index(end).sct1str =scantemp{1,2}(j);
        
        end%if new file was created
        fclose(primwID);
        clear scantemp
    end%if "file start/end date check"
end%for "loop entire index"


%% Sort index by time
tic
[scrap,order] =sort([index(:).t0],'ascend');
index =index(order);
clear scrap order
toc




'files found crossing midnight ='
count





        
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