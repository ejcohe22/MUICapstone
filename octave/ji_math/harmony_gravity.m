function biased_r = harmony_gravity(r)
% HARMONY_GRAVITY  applies a "gravity" bias to a ratio based on YottaDB ^HARMONY
%
% fetched_val = ^HARMONY (long-term harmonic average ratio)
% if dist(r, fetched_val) is small, pull r toward fetched_val.
%
% NEW: Stores history in ^HISTORY and sends 'patina' to SC.

  persistent last_update_time;
  if isempty(last_update_time), last_update_time = 0; end
  
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

  % ── ^HISTORY and Patina logic ───────────────────────────────────────
  curr_t = time();
  if (curr_t - last_update_time) > 0.03  % approx 30fps
    % Ensure sibling osc_send.m is findable
    [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(this_dir);

    % Store current ratio in history
    % We use \$increment to escape $ from bash. 
    % In octave sprintf, we need \\\$ to get \$ in the shell.
    system(sprintf('ydb -run %%XCMD "set ^HISTORY(\\\$increment(^HISTORY))=%f"', r));
    
    % Calculate patina (closeness to older harmonic states)
    [~, count_res] = system('ydb -expr "^HISTORY"');
    count = str2double(count_res);
    patina = 0;
    if count > 50
      % look back at an entry from the "middle" of history
      older_idx = max(1, floor(count * 0.5));
      [~, old_res] = system(sprintf('ydb -expr "^HISTORY(%d)"', older_idx));
      old_val = str2double(old_res);
      if ~isnan(old_val)
        % patina is high if we are resonating with our past
        d = abs(log2(r) - log2(old_val));
        patina = exp(-d * 4.0); % narrow window of resonance
      end
    else
      % building up initial patina
      patina = count / 50 * 0.2;
    end
    
    % Send patina to SuperCollider
    osc_send('127.0.0.1', 57120, '/visual/patina', patina);
    
    last_update_time = curr_t;
  end
  % ────────────────────────────────────────────────────────────────────

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
