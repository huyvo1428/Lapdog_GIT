
%% analysis



for i=1:length(tabindex);

find(tabindex(:,3=)





end






%     t(end+1) = sort((100:999)' + 3*rand(900,1));     % non-uniform time
                      %      x = 5*rand(900,1) + 10;             % x(i) is the value at time t(i)
                      spacing = 32; %//8 or 32 second spacing)
                      
                      t(end+1)=scantemp{1,2}(:);
                      tt = ( floor(t(1)):1*spacing:ceil(t(end)) )';
                      %//         (Note that I sorted t above.)
                      
                      % //        I would do this in three fully vectorized lines of code. First, if the breaks were arbitrary and potentially unequal in spacing,
                      %//I would use histc to determine which intervals the data series falls in. Given they are uniform, just do this:
                      
                      
                      inter = 1 + floor((t - t(1))/spacing);
                      %//        Again, if the elements of t were not known to be sorted, I would have used min(t) instead of t(1). Having done that, use accumarray to reduce the results into a mean and standard deviation.
                      
                      imu = accumarray(inter,scantemp{1,3}(:),[],@mean);
                      isd = accumarray(inter,scantemp{1,3}(:),[],@std);
                      
                      vmu = accumarray(inter,scantemp{1,4}(:),[],@mean);
                      vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
                      
                      
