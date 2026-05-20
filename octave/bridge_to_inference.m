function bridge_to_inference(frame)
% BRIDGE_TO_INFERENCE  maps anceps frame descriptors to inference prompts
%                      and sends them to the MUIC Inference Engine via HTTP.
%
% this is the 'glue' that connects the math layer to the visuals.

  inference_url = getenv('INFERENCE_URL');
  if isempty(inference_url)
    inference_url = 'http://localhost:8000';
  end

  % ── prompt construction ──────────────────────────────────────────────
  global CURRENT_TUNING_PHILOSOPHY;
  if isempty(CURRENT_TUNING_PHILOSOPHY)
    tuning_str = '';
  else
    tuning_str = sprintf(', tuned to %s', strrep(CURRENT_TUNING_PHILOSOPHY, '_', ' '));
  end

  if isempty(frame.pairs)
    prompt = sprintf('a dark minimalist void, silence, low contrast, geometric shadows%s', tuning_str);
  else
    % pick the strongest pair (highest salience)
    [~, idx] = max([frame.pairs.salience]);
    p = frame.pairs(idx);
    
    % ── YottaDB ^HARMONY Gravity Update ──────────────────────────────────
    % Update the long-term harmonic average (^HARMONY) with a running average
    % of the current strongest ratio and its strangeness.
    % alpha is the smoothing factor for the long-term average.
    alpha = 0.05;
    curr_ratio = p.num / p.den;
    curr_strange = p.strangeness;

    % Fetch old values from YottaDB (defaulting if not found)
    [st, res] = system('ydb -expr "^HARMONY" 2>/dev/null');
    if st == 0 && ~isempty(res), old_h = str2double(res); else, old_h = 1.5; end
    [st, res] = system('ydb -expr "^HARMONY(\"strangeness\")" 2>/dev/null');
    if st == 0 && ~isempty(res), old_s = str2double(res); else, old_s = 0.4; end
    [st, res] = system('ydb -expr "^HARMONY(\"prime_limit\")" 2>/dev/null');
    if st == 0 && ~isempty(res), old_pl = str2double(res); else, old_pl = 3; end

    if isnan(old_h), old_h = 1.5; end
    if isnan(old_s), old_s = 0.4; end
    if isnan(old_pl), old_pl = 3; end

    % Compute running average (log space for ratio)
    new_h = 2^(log2(old_h) * (1 - alpha) + log2(curr_ratio) * alpha);
    new_s = old_s * (1 - alpha) + curr_strange * alpha;
    
    curr_pl = max([p.prime_factors, 3]); % 3 is the base prime above 2
    new_pl = old_pl * (1 - alpha) + curr_pl * alpha;

    % Persist back to YottaDB using a dummy shell command as requested.
    % We use 'SET_HARMONY' as the dummy script name.
    system(sprintf('ydb -run SET_HARMONY %f %f %f', new_h, new_s, new_pl));
    % Also direct set for simplicity if script doesn't exist
    system(sprintf('ydb -expr "SET ^HARMONY=%f,^HARMONY(\"strangeness\")=%f,^HARMONY(\"prime_limit\")=%f"', new_h, new_s, new_pl));

    % ── ^TIME Temporal Compression ──────────────────────────────────────
    % Record timestamps in ^TIME, calculate 'urgency' based on jitter
    [st, res] = system('ydb -expr "^TIME" 2>/dev/null');
    if st == 0 && ~isempty(res), last_t = str2double(res); else, last_t = frame.wall_seconds; end
    [st, res] = system('ydb -expr "^TIME(\"delta\")" 2>/dev/null');
    if st == 0 && ~isempty(res), last_delta = str2double(res); else, last_delta = 0.033; end

    curr_delta = frame.wall_seconds - last_t;
    jitter = abs(curr_delta - last_delta);
    urgency = min(jitter * 100, 1.0); % scale jitter to urgency 0-1

    system(sprintf('ydb -expr "SET ^TIME=%f,^TIME(\"delta\")=%f"', frame.wall_seconds, curr_delta));

    % ── ^SAND Visual Grain Metadata ─────────────────────────────────────
    % Fetch "grit" from YottaDB ^SAND
    [st, res] = system('ydb -expr "^SAND" 2>/dev/null');
    if st == 0 && ~isempty(res), grit = str2double(res); else, grit = 0; end
    if isnan(grit), grit = 0; end

    % map strangeness to visual adjectives
    if p.strangeness < 0.4
      complexity_str = 'smooth harmonic curves, liquid gold, pure resonance';
    elseif p.strangeness < 0.6
      complexity_str = 'crystalline lattices, geometric patterns, intricate refractions';
    else
      complexity_str = 'chaotic nebulae, jagged textures, high energy dissonance';
    end

    % map blend_name (from ji_math) to visual themes
    % blend names are like 'power-sweetness', 'blue-alien', etc.
    theme_str = strrep(p.blend_name, '-', ' and ');

    prompt = sprintf('abstract generative art representing %s, %s, driven by %0.f hz and %0.f hz peaks, intensity %.2f%s', ...
                     theme_str, complexity_str, p.freq_high, p.freq_low, frame.loudness, tuning_str);

    % Append metadata-driven descriptors
    if grit > 0.5
      prompt = [prompt ', hyper-detailed granular textures'];
    end
    if urgency > 0.5
      prompt = [prompt ', high urgency temporal compression'];
    end
  end

  % ── execution ────────────────────────────────────────────────────────
  % construct JSON payload (manually since we don't have a JSON lib)
  % escape double quotes if they ever appear (unlikely here)
  payload = sprintf('{"prompt": "%s"}', prompt);
  
  % use system curl for the HTTP POST
  cmd = sprintf('curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer dev-key" -d ''%s'' %s/generate', ...
                payload, inference_url);
  
  % we run this in the background or just accept the blocking call for now.
  % given the analysis rate vs inference rate, we might want to skip frames.
  persistent last_sent_time = 0;
  current_time = frame.wall_seconds;
  
  % rate limit: don't hammer the inference server faster than once per 0.5s
  if (current_time - last_sent_time) > 0.5
    [status, ~] = system(cmd);
    if status == 0
      last_sent_time = current_time;
      printf('bridge_to_inference: sent prompt: "%s"\n', prompt);
    else
      printf('bridge_to_inference: ERROR sending to %s\n', inference_url);
    end
  end
  fflush(stdout);
end
