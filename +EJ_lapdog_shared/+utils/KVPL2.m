%
% Class modelling an ordered key-value pair list (KVPL).
% Replaces older standard struct KVPL that could be modified with functions EJ_lapdog_shared.utils.KVPL.* .
%
% MATLAB "value class" which implies that it is immutable and passed-by-value.
%
%
% IMPLEMENTATION NOTES
% ====================
% KVPLs have some characteristics of
%   (1) sets (of keys),
% but also the properties of
%   (2) ordered lists, and 
%   (3) "values" (same key can have different values).
% This makes the "fundamental operations" on KVPLs, and hence fundamental methods to implement less obvious. The methods
% have therefore been chosen and named depending on which properties they use. The method for joining/merging/combining
% KVPLs with non-overlapping keys is therefore called to refer to that it is a "list" operation that produces a
% predictable ordering, not a set operation (e.g. union).
% (1) Set-like operations have been chosen as unambiguous set-like operations which naturally and unambiguously preserve
% order:
%       diff, intersection, subset               : KVPL + key set --> KVPL
%       overwrite_intersection, overwrite_subset : KVPL + KVPL    --> KVPL
%       equals(... 'ignore key ordering')        : KVPL + KVPL --> boolean
% Other set-like operations can be conceived of but they do not seem to be as easily/naturally expressed as one might think, e.g.
% method for combining two KVPLs (KVPL + KVPL --> KVPL).
% (2) List-like operations:
%       append                              : KVPL + KVPL --> KVPL
%       equals(... 'consider key ordering') : KVPL + KVPL --> boolean
%
%
% Initially created 2018-11-06 by Erik P G Johansson.
% Based on earlier functions and a standardized and analogous struct.
%
classdef KVPL2
    % PROPOSAL: Change name KVPL2-->KVPL, when has removed the old use of old KVPL data struct.
    %
    % PROPOSAL: Permit non-string values.
    % TODO-DECISION: Permit/forbid empty string keys?
    % 
    % PROPOSAL: get/read-only properties so that can print with print_variable_recursively.
    %
    % PROPOSAL: Replace with containers.Map
    % TODO-DECISION: Ignore ordering?!!
    % PROPOSAL: Convert to handle object.
    %   
    % PROPOSAL: More (public) static methods instead of instance methods.
    %   PRO: Easier to write "formulas".
    %   CON: Makes class unnecessary.
    %       CON: Still has encapsulation.
    %   CON: Longer code/calls.
    %
    % NOTE: ~Problem is that KVLPs are not sets, but also have properties ordering AND values.
    %
    % NOTE: Can obtain KVPL.keys as set (not list) to use as argument in methods.
    % NOTE: Can obtain KVPL.keys as list (not set) to use as argument in methods.
    %
    % PROPOSAL: 
    %   Have pure set operations methods. Return only keys.
    %       CON: Set operations methods not needed since too simple: union, intersection, diff, xor
    %       .subset/.keep(keySet)     % Remove unmentioned keys. Keep sorting.
    %       .subset/.keep(iList)      % Remove unmentioned keys. Keep/set sorting?
    %   Have pure assignment/read methods specifying only string keys.
    %       ? .assign(keySet, values)    % Assign subset of preexisting keys. Keep ordering
    %       ? .assign(iList,   values)   % Assign subset of preexisting keys. Keep/set sorting?
    %   Have pure ordering method(s), specifying only keys.
    %   CON: Inefficient implementing algorithms which could be done with indices.
    %       NOTE: Indices change when adding/removing keys and reordering.
    %       CON: Premature optimization
    %   PROPOSAL: Methods with index arguments.
    %
    % PROPOSAL: merge/combine
    %   'assert no intersection'
    %       Kvpl = Kvpl1.append(Kvpl2)    % Asserts no intersection.
    %   'assert identical intersection'
    %       KvplInt1 = Kvpl1.intersection(Kvpl2.keys)
    %       KvplInt2 = Kvpl2.intersection(Kvpl1.keys)
    %       assert KvplInt1.equals(KvplInt2, 'ignore key order')
    %       Kvpl = Kvpl1.append( Kvpl2.diff(Kvpl1.keys) )   % Asserts no intersection
    %       Kvpl = Kvpl.reorder(Kvpl1, 'unsorted last');
    %   'use 1'
    %       KvplInt1 = Kvpl1.intersection(Kvpl2.keys)
    %       KvplInt2 = Kvpl2.intersection(Kvpl1.keys)
    %       Kvpl = Kvpl1.append( Kvpl2.diff(Kvpl1.keys) )   % Asserts no intersection
    %       Kvpl = Kvpl.reorder(Kvpl1, 'unsorted last');
    %   
    % NOTE: Lapdog (2018-11-07) uses old KVPL functions:
    %   add_kv_pairs
    %   read_value
    %   add_copy_of_kv_pair
    %   add_kv_pair
    %   add_kv_pairs
    %   overwrite_values(..., 'require preexisting keys')
    %   KVPL.overwrite_values(..., 'add if not preexisting')
    %   merge
    %   order_by_key_list
    %   delete_keys
    
    properties(SetAccess=private,GetAccess=public)
        keys      % Must be column vector.
        values    % Must be column vector.
    end
    
    
    
    methods(Access=public)
        
        % Constructor
        %
        % ARGUMENTS
        % =========
        % varargin :
        %   alt 1:      Initialize empty KVPL.
        %       (0 arguments)
        %   alt 2:
        %       kvplContentCellArray : Nx2 cell array of strings.
        %                        kvplContentCellArray{iRow,1} = key
        %                        kvplContentCellArray{iRow,2} = value
        %   alt 3:
        %       keys   : Column cell array of strings.
        %       values : Column cell array.
        %   
        function obj = KVPL2(varargin)
            import EJ_lapdog_shared.utils.*

            if nargin == 0
                obj.keys   = cell(0,1);
                obj.values = cell(0,1);
                
            elseif (nargin == 1) && iscell(varargin{1})                
                kvplContentCellArray = KVPL2.normalize_empty(varargin{1}, cell(0,2));
                
                % ASSERTION
                if size(kvplContentCellArray,2) ~= 2
                    error('Illegal size of cell array.')
                end
                
                obj.keys   = kvplContentCellArray(:,1);
                obj.values = kvplContentCellArray(:,2);
                
            elseif nargin == 2
                % Normalize {}, and force column vectors.
                obj.keys   = KVPL2.normalize_empty(varargin{1}(:), cell(0,1));
                obj.values = KVPL2.normalize_empty(varargin{2}(:), cell(0,1));
                
            else
                error('Illegal argument(s).')
            end
            
            
            
            % ASSERTIONS: Check fields.
            assert.castring_set(obj.keys)
            if size(obj.keys, 2) ~= 1
                error('obj.keys is not a column vector.')
            end
            if size(obj.values, 2) ~= 1
                error('obj.values is not a column vector.')
            end
            if numel(obj.keys) ~= numel(obj.values)
                error('obj.keys and obj.values do not have identical size.')
            end
        end
        


        function isEmpty = isempty(obj)
            isEmpty = isempty(obj.keys);
        end



        % Check if object equals other KVPL.
        %
        % policy : String
        function eq = equals(obj, Kvpl2, policy)
            % PROPOSAL: Shorthand methods instead of policy. equals_cko, equals_iko            
            % PROPOSAL: Policy for just comparing keys, in and out of order.
            
            EJ_lapdog_shared.utils.assert.isa(Kvpl2, 'EJ_lapdog_shared.utils.KVPL2')
            
            if numel(obj.keys) ~= numel(Kvpl2.keys)
                eq = false;
                return
            end
            
            switch(policy)
                case 'consider key order'
                    if any(~strcmp(obj.keys, Kvpl2.keys))
                        eq = false;
                        return
                    end
                case 'ignore key order'
                    ;
                otherwise
                    error('Illegal policy argument.')
            end

            [keysSorted1, iSort1] = sort(obj.keys);
            [keysSorted2, iSort2] = sort(Kvpl2.keys);

            if any(~strcmp(keysSorted1, keysSorted2))
                eq = false;
                return
            end

            eq = all(strcmp(obj.values(iSort1), Kvpl2.values(iSort2)));
        end
        
        
        
        % ASSERTION: key must pre-exist (otherwise method would be called append_*).
        function Kvpl = set_value(obj, key, value)
            i = find(strcmp(key, obj.keys));
    
            % ASSERTION
            if length(i) ~= 1
                error('obj does not contain the specified key="%s".', key)
            end
            
            obj.values{i} = value;
            Kvpl = EJ_lapdog_shared.utils.KVPL2(obj.keys, obj.values);
        end
        
        
        
        function value = get_value(obj, key)
            i = find(strcmp(key, obj.keys));
    
            % ASSERTION
            if length(i) ~= 1
                error('obj does not contain the specified key="%s".', key)
            end
            
            value = obj.values{i};
        end
        
        
        
        % Remove keys from KVPL. Does not require keySet to be a subset of keys.
        % Keeps ordering.
        %
        % NOTE: Complements obj.intersection.
        % NOTE: Named after the set operation "difference". Could also be thought of as "delete_keys".
        function Kvpl = diff(obj, keySet)
            % PROPOSAL: Rename "difference", remove_intersection
            import EJ_lapdog_shared.utils.*
            
            assert.castring_set(keySet)
            [diffKeyList, iDiff] = setdiff(obj.keys, keySet);
            
            Kvpl = KVPL2(...
                obj.keys(iDiff), ...
                obj.values(iDiff));
        end
        
        

        % Only keep specified keys in KVPL. Does not require keySet to be a subset of keys.
        % Keeps ordering.
        %
        % NOTE: Complements obj.diff.
        % NOTE: Named after the set operation. Could also be thought of as "keep_keys", "remove_all_keys_except".
        function Kvpl = intersection(obj, keySet)
            [intKeysList, iInt, junk] = intersect(obj.keys, keySet);
            
            Kvpl = EJ_lapdog_shared.utils.KVPL2(...
                obj.keys(iInt), ...
                obj.values(iInt));
        end
        
        
        
        function Kvpl = subset(obj, keySubset)
            % ASSERTION
            diffKeySet = setdiff(keySubset, obj.keys);
            if numel(diffKeySet) > 0
                error('keySubset does not represent a subset of obj.keys.')
            end

            Kvpl = obj.intersection(keySubset);
        end



        % NOTE: No "prepend" method/policy since that can be achieved by exchanging the object and argument.
        % ASSERTION: No intersection of key sets.
        function Kvpl = append(obj, Kvpl)
            import EJ_lapdog_shared.utils.*
            
            assert.isa(Kvpl, 'EJ_lapdog_shared.utils.KVPL2')
            
            Kvpl = KVPL2(...
                [obj.keys; Kvpl.keys], ...
                [obj.values; Kvpl.values]);   % NOTE: Constructor asserts unique keys.
        end
        
        
        
        % NOTE: To copy a key-value from a KVPL, use Kvpl = Kvpl.append(Kvpl.subset({key}))
        % ASSERTION: No intersection of key sets.
        function Kvpl = append_kvp(obj, key, value)
            Kvpl = EJ_lapdog_shared.utils.KVPL2(...
                [obj.keys;   key], ...
                [obj.values; value]);
        end
        
        
        
        % For the intersection of keys, assign obj values with values from KvplSrc.
        % obj and Kvpl will have the same set of keys, in the same order.
        function Kvpl = overwrite_intersection(obj, KvplSrc)
            % PROPOSAL: Better name to better reflect meaning.
            %   PROPOSAL: copy_from_intersection, replace/substitute_values_from, replace, replace_intersection,
            %             overwrite_intersection
            import EJ_lapdog_shared.utils.*
            
            assert.isa(KvplSrc, 'EJ_lapdog_shared.utils.KVPL2')
            [intKeysList, iInt, jInt] = intersect(obj.keys, KvplSrc.keys);
            
            obj.values(iInt) = KvplSrc.values(jInt);
            Kvpl = KVPL2(obj.keys, obj.values);
        end



        % For the subset of keys, assign obj values with values from KvplSubsetSrc.
        % Like overwrite_intersection, except that KvplSubsetSrc must have keys which are a subset of obj.keys.
        %
        % obj and Kvpl will have the same set of keys, in the same order.
        function Kvpl = overwrite_subset(obj, KvplSubsetSrc)
            % PROPOSAL: Better name to better reflect meaning.
            %   PROPOSAL: copy_from_subset, replace/substitute_values_from, replace, replace_subset,
            %             overwrite_subset

            % ASSERTION
            diffKeySet = setdiff(KvplSubsetSrc.keys, obj.keys);
            if numel(diffKeySet) > 0
                error('KvplSubsetSrc does not represent a subset of obj.keys.')
            end

            Kvpl = obj.overwrite_intersection(KvplSubsetSrc);
        end



        % Order key-value pairs according to a list of keys.
        % Remaining key-value pairs will be added at the end in their previous internal order.
        %
        %
        % ARGUMENTS
        % =========
        % keyOrderList   : Cell array of unique strings.
        %                  NOTE: Does not assume any relationship between obj.keys and keyOrderList
        %                  (either may contain elements not existing in the other).
        % unsortedPolicy : String.
        %   'sorted-unsorted'
        %   'unsorted-sorted'
        %
        function Kvpl = reorder(obj, keyOrderList, unsortedPolicy)
            % PROPOSAL: Policy for relationship between obj.keys and keyOrderList.
            %   Assert keyOrderList is subset of obj.keys.
            %   Assert obj.keys     is subset of keyOrderList.
            %   Assert obj.keys     and          yOrderList    are identical (except for order).
            
            import EJ_lapdog_shared.utils.*

            % ASSERTION
            assert.castring_set(keyOrderList)
            
            % NORMALIZATION
            keyOrderList = keyOrderList(:);   % Force column vector. Row/column otherwise influences iOrdered.

            % Derive iOrdered.
            [junk, iOrdered] = ismember(keyOrderList, obj.keys);
            iOrdered = iOrdered(find(iOrdered));   % Remove zeros. "find" can not be removed despite MATLAB's suggestion.
            
            % Derive iUnsorted = Indices into obj.keys that are not already in iOrdered.
            % NOTE: Want to keep the original order.
            hasNoNewLocation           = ones(size(obj.keys));
            hasNoNewLocation(iOrdered) = 0;
            iUnsorted = find(hasNoNewLocation);
            
            switch(unsortedPolicy)
                case 'sorted-unsorted'
                    iOrderTot = [iOrdered; iUnsorted];
                case 'unsorted-sorted'
                    iOrderTot = [iUnsorted; iOrdered];
                otherwise
                    error('Illegal argument unsortedPolicy="%s"', unsortedPolicy)
            end
            
            % ASSERTION: Internal consistency check.
            if (length(iOrderTot) ~= length(obj.keys)) || any(sort(iOrderTot) ~= (1:length(obj.keys))')
                error('ERROR: Likely bug in algorithm');
            end
            
            Kvpl = KVPL2(obj.keys(iOrderTot), obj.values(iOrderTot));
        end
        
    end    % methods(Access=public)
    
    
    
    methods(Static, Access=private)
        
        % Internal helper function
        % NOTE: Only replaces a 0x0x0x... array to be able to have assertions give error on e.g. 0x6 normalized format is Nx2.
        function v = normalize_empty(v, emptyReplacement)
            if ~any(size(v))
                v = emptyReplacement;
            end
        end
        
    end    % methods(Access=private)
end    % classdef
