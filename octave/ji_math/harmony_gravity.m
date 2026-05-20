function biased_r = harmony_gravity(r)
% HARMONY_GRAVITY  applies a "gravity" bias to a ratio based on YottaDB ^HARMONY
%
% fetched_val = ^HARMONY (long-term harmonic average ratio)
% if dist(r, fetched_val) is small, pull r toward fetched_val.

  % 1. Fetch from YottaDB
  % We use ydb -expr to get the value of the ^HARMONY global.
  % Default to 1.5 (3/2) if not found or error.
  
  [status, result] = system('ydb -expr "^HARMONY" 2>/dev/null');
  
  if status == 0 && ~isempty(result)
    harmony_val = str2double(result);
    if isnan(harmony_val) || harmony_val <= 0
      harmony_val = 1.5; % Default to 3/2 (Perfect Fifth)
    end
  else
    harmony_val = 1.5; % Default to 3/2
  end

  % 2. Apply Bias
  % pulling detections toward the '^HARMONY' value if the distance is small.
  % Distance is measured in octaves (log2).
  
  dist = abs(log2(r) - log2(harmony_val));
  
  % Gravity threshold: 50 cents (approx. 0.0417 octaves)
  threshold = 50 / 1200;
  
  if dist < threshold
    % Pull ratio toward harmony_val. 
    % Strength increases as distance decreases.
    strength = 0.5 * (1 - dist / threshold); 
    
    biased_log_r = log2(r) * (1 - strength) + log2(harmony_val) * strength;
    biased_r = 2^biased_log_r;
  else
    biased_r = r;
  end
end
