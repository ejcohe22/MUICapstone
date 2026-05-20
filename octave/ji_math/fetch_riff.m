function riff = fetch_riff()
% FETCH_RIFF  retrieves a melodic fragment from YottaDB global ^RIFF
%
% This uses ydb -expr to fetch the string representation of the riff.
% If not found or error, returns an empty string.

  [status, result] = system('ydb -expr "^RIFF" 2>/dev/null');
  
  if status == 0 && ~isempty(result)
    % Clean up result (trim whitespace/newlines)
    riff = strtrim(result);
    % Remove quotes if present (YottaDB -expr might return quoted string)
    if length(riff) >= 2 && riff(1) == '"' && riff(end) == '"'
      riff = riff(2:end-1);
    end
  else
    riff = '';
  end
end
