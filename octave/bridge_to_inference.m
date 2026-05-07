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
  if isempty(frame.pairs)
    prompt = 'a dark minimalist void, silence, low contrast, geometric shadows';
  else
    % pick the strongest pair (highest salience)
    [~, idx] = max([frame.pairs.salience]);
    p = frame.pairs(idx);
    
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
    
    prompt = sprintf('abstract generative art representing %s, %s, driven by %0.f hz and %0.f hz peaks, intensity %.2f', ...
                     theme_str, complexity_str, p.freq_high, p.freq_low, frame.loudness);
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
