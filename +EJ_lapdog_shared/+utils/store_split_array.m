%
% Utility for saving large arrays in multiple .mat files to circumvent MATLAB's 2 GiB (uncompressed) size limit.
% 
% Accepts any array, converts it to a 1D which is then split up in parts (different index ranges) which are stored in
% one file each.
%
%
% NOTE: Using MATLAB's "save" with the flag "-v7.3" should in theory solve the same problem but has been shown to be
% impractically slow and generate too large files.
% NOTE: Can not choose filenames entirely.
% NOTE: Will overwrite preexisting files.
%
%
% Initially created 2018-12-03 by Erik P G Johansson.
%
classdef store_split_array
    % PROPOSAL: Change name to something array.
    %
    % PROPOSAL: Separate functions for splitting and merging array.
    % PROPOSAL: Convert N-D array to/from 1D array.
    % PROPOSAL: Split default filenames from save/load.
    %
    % PROPOSAL: Way of checking that all parts have been loaded (all indices filled).
    %   PROPOSAL: Count files and compare to stored variable.
    % TODO-DECISION: How choose filenames?
    % TODO-DECISION: How know how many/which files to read?
    %   PROPOSAL: Increment counter+prefix. End when does not find another file with higher counter value.
    %   PROPOSAL: Store how many files should be read.
    %   PROPOSAL: Separate function for splitting data (choosing indices and maybe selecting metadata) and choosing filenames.

    methods(Static)



        function save(array, pathPrefix, nIndicesPerFile)

            % ASSERTIONS
            assert(nIndicesPerFile >= 1)
            
            operationId = rand();    % Unique "operation ID" to store in files to make it possible for the reader to verify that the loaded files belong together.
            saveTimestamp = datestr(now, 'YYYY-mm-DD, HH:MM:SS');
            
            arraySize = size(array);    % NOTE: Defining variable just so that "save" can store/save it.
            iTotal    = numel(array);
            
            % Convert array: N-D --> 1-D
            array = reshape(array, [iTotal, 1]);
            
            [iPartBeginArray, iPartEndArray] = EJ_lapdog_shared.utils.store_split_array.split_indices(iTotal, nIndicesPerFile);
            nParts = numel(iPartBeginArray);

            for jPart = 1:nParts

                iPartBegin = iPartBeginArray(jPart);
                iPartEnd   = iPartEndArray(jPart);

                arrayPart = array(iPartBegin:iPartEnd);    % NOTE: Defining variable just so that "save" can store/save it.

                filePath = EJ_lapdog_shared.utils.store_split_array.get_file_path(pathPrefix, jPart);
                save(filePath, 'arrayPart', 'iPartBegin', 'iPartEnd', 'nParts', 'arraySize', 'operationId', 'saveTimestamp');

            end
        end



        function array = load(pathPrefix)
            jPart = 1;
            
            firstOperationId = [];
            
            while true
                filePath = EJ_lapdog_shared.utils.store_split_array.get_file_path(pathPrefix, jPart);
                load(filePath, 'arrayPart', 'iPartBegin', 'iPartEnd', 'nParts', 'arraySize', 'operationId');
                
                % ASSERTION: 
                if isempty(firstOperationId)
                    firstOperationId = operationId;
                elseif operationId ~= firstOperationId
                    error('operationId differs between array part files. Can/will/should not combine to array.');
                end
                
                array(iPartBegin:iPartEnd) = arrayPart;    % NOTE: Works also if array is unitialized.
                
                if jPart >= nParts
                    break
                end
                jPart = jPart + 1;
            end
            
            % Convert array: 1-D --> N-D
            array = reshape(array, arraySize);
        end

    end
    
    
    
    methods(Static, Access=private)
        
        function filePath = get_file_path(pathPrefix, iPart)
            filePath = [pathPrefix, sprintf('%06i.mat', iPart)];
        end



        function [iPartBeginArray, iPartEndArray] = split_indices(nTotal, nPerFile)
            % ASSERTIONS
            assert(nTotal   >= 0)
            assert(nPerFile >= 1)
            
            iPartBeginArray = [];
            iPartEndArray   = [];
            iPartBegin = 1;

            while true
                iPartEnd = min(iPartBegin + nPerFile-1, nTotal);
                
                iPartBeginArray(end+1) = iPartBegin;
                iPartEndArray(end+1)   = iPartEnd;
                
                
                if (nTotal <= iPartEnd)
                    break
                end
                
                iPartBegin = iPartEnd + 1;
            end

        end    

    end   % methods

end
