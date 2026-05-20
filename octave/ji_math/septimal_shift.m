function biased_r = septimal_shift(r)
% SEPTIMAL_SHIFT  applies a "blue note" frequency bias to 7-limit ratios from YottaDB ^BLUE
%
% fetched_val = ^BLUE (target frequency for septimal intervals)
% If r is approximately a 7-limit ratio, pull r toward ^BLUE.

  % 1. Estimate if ratio is septimal
  % Use a reasonable max_denom for the quick check
  [n, d] = rat(r, 1e-3);
  
  [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
  addpath(this_dir);
  monzo = prime_factorize(n, d);
  
  is_septimal = (length(monzo) >= 4 && monzo(4) ~= 0);
  
  if ~is_septimal
    biased_r = r;
    return;
  end

  % 2. Fetch from YottaDB
  [status, result] = system('ydb -expr "^BLUE" 2>/dev/null');
  
  if status == 0 && ~isempty(result)
    blue_target = str2double(result);
    if isnan(blue_target) || blue_target <= 0
      blue_target = 1.75; % Default to 7/4 (Septimal Harmonic Seventh)
    end
  else
    blue_target = 1.75; % Default to 7/4
  end

  % 3. Apply Bias
  % pulling detections toward the '^BLUE' value if the distance is small.
  dist = abs(log2(r) - log2(blue_target));
  
  % Septimal "blue" notes are often flexible, use a slightly wider threshold.
  % 60 cents (0.05 octaves)
  threshold = 60 / 1200;
  
  if dist < threshold
    % Pull ratio toward blue_target. 
    % Strength increases as distance decreases.
    strength = 0.4 * (1 - dist / threshold); 
    
    biased_log_r = log2(r) * (1 - strength) + log2(blue_target) * strength;
    biased_r = 2^biased_log_r;
  else
    biased_r = r;
  end
end
