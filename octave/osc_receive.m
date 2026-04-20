function osc_receive(varargin)
% OSC_RECEIVE  listen on 127.0.0.1:57121 for anceps open sound control
%              bundles, form ratios from peak pairs, call affect and blend
%              on each ratio, and hand the results to a per frame callback.
%
% blocking loop. runs until ctrl-c. one bundle in, one callback call out.
%
% options (name, value pairs):
%   'host'           bind address, default '127.0.0.1'
%   'port'           udp port, default 57121
%   'max_denom'      cap on rational approximation denominator, default 64
%   'min_cents'      minimum interval size to keep a pair, default 50
%   'callback'       function handle called once per frame with one arg:
%                    a frame struct (see below). default is a printer.
%   'timeout_ms'     udp read timeout in milliseconds, default 1000
%
% frame struct passed to callback:
%   .frame_number        from /anceps/frame
%   .wall_seconds        from /anceps/frame
%   .sample_rate         from /anceps/frame
%   .window_size         from /anceps/frame
%   .loudness            from /anceps/descriptors
%   .centroid            from /anceps/descriptors
%   .flatness            from /anceps/descriptors
%   .onset               from /anceps/descriptors
%   .flux                from /anceps/descriptors if present, else nan
%   .peak_count          number of peaks in /anceps/peaks
%   .peaks               n by 2 matrix of [freq_hz, magnitude] rows
%   .pairs               struct array, one entry per ratio. fields:
%     .freq_low          lower frequency in hertz
%     .freq_high         higher frequency in hertz
%     .mag_low           magnitude of the lower peak
%     .mag_high          magnitude of the higher peak
%     .salience          mag_low times mag_high (pair strength)
%     .cents             interval size in cents (always positive)
%     .num               numerator of rational approximation
%     .den               denominator of rational approximation
%     .strangeness       from affect('strangeness', num, den)
%     .blend_name        from blend('name', num, den)
%     .prime_factors     from affect('prime_character', num, den)
%
% ratios are formed as all pairs (N choose 2) of the incoming peak array.
% the higher frequency becomes the numerator, the lower becomes the
% denominator, so every ratio is >= 1. the rational approximation is
% reduced to the octave [1, 2) before being handed to the math layer so
% that 3/1 and 3/2 collapse to the same prime content with the same
% strangeness.
%
% depends on the octave sockets package for udp.
%
% example:
%   pkg load sockets
%   addpath('/path/to/anceps/octave/ji_math')
%   osc_receive()                    % default printer callback
%   osc_receive('callback', @my_fn)  % custom callback

  % ── option parsing ────────────────────────────────────────────────────
  opts.host = '127.0.0.1';
  opts.port = 57121;
  opts.max_denom = 64;
  opts.min_cents = 50;
  opts.callback = @default_printer;
  opts.timeout_ms = 1000;
  for i = 1:2:numel(varargin)
    opts.(varargin{i}) = varargin{i+1};
  end

  % ── set up udp socket ────────────────────────────────────────────────
  pkg load sockets;
  sock = socket(AF_INET, SOCK_DGRAM, 0);
  % bind to host:port
  rc = bind(sock, opts.port);
  if rc < 0
    error('osc_receive: bind to port %d failed', opts.port);
  end

  printf('osc_receive: listening on %s:%d\n', opts.host, opts.port);
  printf('osc_receive: ctrl-c to stop\n');
  fflush(stdout);

  % buffer large enough to hold a bundle with the maximum peak count
  % (8 peaks * 2 floats each = 16 floats in /anceps/peaks, plus room for
  % frame and descriptors headers and bundle framing)
  buf_size = 4096;

  try
    while true
      % blocking recv. returns a uint8 vector of received bytes.
      [data, count] = recv(sock, buf_size);
      if count <= 0
        continue;
      end
      bytes = uint8(data(1:count));

      % ── parse the bundle ──────────────────────────────────────────────
      messages = parse_osc_bundle(bytes);
      if isempty(messages)
        continue;
      end

      % ── assemble the frame struct from the three messages ────────────
      frame = assemble_frame(messages);
      if isempty(frame)
        continue;
      end

      % ── form pairs and compute ratios ────────────────────────────────
      frame.pairs = compute_pairs(frame.peaks, opts);

      % ── hand off to the callback ─────────────────────────────────────
      opts.callback(frame);
    end
  catch err
    disconnect(sock);
    rethrow(err);
  end

  disconnect(sock);
end


% ══════════════════════════════════════════════════════════════════════════
% open sound control decoding
% ══════════════════════════════════════════════════════════════════════════

function messages = parse_osc_bundle(bytes)
% parse either a bundle (#bundle\0 + timetag + size+msg + size+msg ...)
% or a single message. returns a cell array of message structs.
  messages = {};
  if numel(bytes) < 8
    return;
  end
  head = char(bytes(1:8)');
  if strcmp(head, ['#bundle' char(0)])
    % skip 8 byte header plus 8 byte timetag = 16 bytes
    idx = 17;
    while idx <= numel(bytes)
      if idx + 3 > numel(bytes)
        break;
      end
      sz = read_int32(bytes, idx);
      idx = idx + 4;
      if sz <= 0 || idx + sz - 1 > numel(bytes)
        break;
      end
      msg_bytes = bytes(idx:idx+sz-1);
      msg = parse_osc_message(msg_bytes);
      if ~isempty(msg)
        messages{end+1} = msg;
      end
      idx = idx + sz;
    end
  else
    msg = parse_osc_message(bytes);
    if ~isempty(msg)
      messages = {msg};
    end
  end
end


function msg = parse_osc_message(bytes)
% decode a single open sound control message into a struct with
% .address (string) and .args (cell array of values).
  msg = [];
  n = numel(bytes);
  if n < 8
    return;
  end
  [address, idx] = read_ostring(bytes, 1);
  if idx > n
    return;
  end
  [typetag, idx] = read_ostring(bytes, idx);
  if isempty(typetag) || typetag(1) ~= ','
    return;
  end
  args = {};
  for t = 2:numel(typetag)
    tag = typetag(t);
    switch tag
      case 'i'
        if idx + 3 > n, return; end
        args{end+1} = read_int32(bytes, idx);
        idx = idx + 4;
      case 'f'
        if idx + 3 > n, return; end
        args{end+1} = read_float32(bytes, idx);
        idx = idx + 4;
      case 's'
        [s, idx] = read_ostring(bytes, idx);
        args{end+1} = s;
      otherwise
        % unknown types are ignored; skip 4 bytes as a safety default
        idx = idx + 4;
    end
  end
  msg.address = address;
  msg.args = args;
end


function [s, new_idx] = read_ostring(bytes, idx)
% null terminated string padded to 4 byte boundary
  start = idx;
  while idx <= numel(bytes) && bytes(idx) ~= 0
    idx = idx + 1;
  end
  s = char(bytes(start:idx-1)');
  % skip null and pad to 4 byte boundary
  idx = idx + 1;
  pad = mod(idx - 1, 4);
  if pad > 0
    idx = idx + (4 - pad);
  end
  new_idx = idx;
end


function v = read_int32(bytes, idx)
% big endian 32 bit signed integer
  b = uint32(bytes(idx:idx+3));
  u = bitshift(b(1), 24) + bitshift(b(2), 16) + bitshift(b(3), 8) + b(4);
  v = double(typecast(uint32(u), 'int32'));
end


function v = read_float32(bytes, idx)
% big endian ieee 754 single precision
  b = uint8(bytes(idx:idx+3));
  % swap to little endian before typecast since octave is native little
  b = b([4 3 2 1]);
  v = double(typecast(b, 'single'));
end


% ══════════════════════════════════════════════════════════════════════════
% message assembly
% ══════════════════════════════════════════════════════════════════════════

function frame = assemble_frame(messages)
% walk the messages collected from a bundle and assemble a single frame
% struct. returns empty if the bundle is malformed or missing required
% messages.
  frame = [];
  have_frame = false;
  have_desc = false;
  have_peaks = false;
  out.flux = nan;  % reserved field; nan if absent
  for k = 1:numel(messages)
    m = messages{k};
    switch m.address
      case '/anceps/frame'
        if numel(m.args) >= 4
          out.frame_number = m.args{1};
          out.wall_seconds = m.args{2};
          out.sample_rate  = m.args{3};
          out.window_size  = m.args{4};
          have_frame = true;
        end
      case '/anceps/descriptors'
        if numel(m.args) >= 4
          out.loudness = m.args{1};
          out.centroid = m.args{2};
          out.flatness = m.args{3};
          out.onset    = m.args{4};
        end
        if numel(m.args) >= 5
          out.flux = m.args{5};  % appended in v0.2
        end
        have_desc = numel(m.args) >= 4;
      case '/anceps/peaks'
        if numel(m.args) >= 1
          n = m.args{1};
          if n == 0 || 2*n + 1 > numel(m.args)
            out.peak_count = n;
            out.peaks = zeros(0, 2);
          else
            out.peak_count = n;
            p = zeros(n, 2);
            for i = 1:n
              p(i, 1) = m.args{2*i};      % freq
              p(i, 2) = m.args{2*i + 1};  % mag
            end
            out.peaks = p;
          end
          have_peaks = true;
        end
    end
  end
  if have_frame && have_desc && have_peaks
    frame = out;
  end
end


% ══════════════════════════════════════════════════════════════════════════
% ratio formation
% ══════════════════════════════════════════════════════════════════════════

function pairs = compute_pairs(peaks, opts)
% for each unordered pair of peaks, compute the rational approximation
% and run it through affect and blend. peaks shorter than 2 rows
% produces an empty struct array.
  pairs = struct('freq_low', {}, 'freq_high', {}, ...
                 'mag_low', {}, 'mag_high', {}, ...
                 'salience', {}, 'cents', {}, ...
                 'num', {}, 'den', {}, ...
                 'strangeness', {}, 'blend_name', {}, ...
                 'prime_factors', {});
  n = size(peaks, 1);
  if n < 2
    return;
  end
  % sort ascending by frequency so pairs are well defined
  peaks = sortrows(peaks, 1);
  for i = 1:n-1
    for j = i+1:n
      fl = peaks(i, 1);
      fh = peaks(j, 1);
      ml = peaks(i, 2);
      mh = peaks(j, 2);
      if fl <= 0 || fh <= 0
        continue;
      end
      cents = 1200 * log2(fh / fl);
      if cents < opts.min_cents
        continue;  % too close to call
      end
      % reduce raw ratio to [1, 2) before approximating
      r = fh / fl;
      while r >= 2
        r = r / 2;
      end
      [num, den] = rat_cap(r, opts.max_denom);
      if num < den
        % sanity: after octave reduction num should be >= den
        % (but rat can give us either order depending on tolerance;
        %  swap to enforce ratio >= 1)
        tmp = num; num = den; den = tmp;
      end
      % now hand to the math layer
      strangeness = affect('strangeness', num, den);
      blend_name  = blend('name', num, den);
      prime_char  = affect('prime_character', num, den);

      p = struct();
      p.freq_low = fl;
      p.freq_high = fh;
      p.mag_low = ml;
      p.mag_high = mh;
      p.salience = ml * mh;
      p.cents = cents;
      p.num = num;
      p.den = den;
      p.strangeness = strangeness;
      p.blend_name = blend_name;
      p.prime_factors = prime_char.prime_factors;
      pairs(end+1) = p;
    end
  end
end


function [num, den] = rat_cap(x, max_denom)
% continued fraction rational approximation with a denominator cap.
% uses the stern-brocot-style tolerance that gives the closest ratio
% with denominator <= max_denom.
  [num, den] = rat(x, 1.0 / (2 * max_denom));
  % if rat exceeded the cap (it can in pathological cases), fall back
  % to a coarser tolerance until we're within bounds.
  tol = 1.0 / (2 * max_denom);
  while den > max_denom
    tol = tol * 2;
    [num, den] = rat(x, tol);
    if tol > 0.5
      % at this point the input is basically noise; snap to 1/1
      num = 1; den = 1;
      break;
    end
  end
end


% ══════════════════════════════════════════════════════════════════════════
% default callback: print a compact summary of each frame
% ══════════════════════════════════════════════════════════════════════════

function default_printer(frame)
  printf('\nframe %d  t=%.3fs  loud=%.3f  cent=%6.0fhz  flat=%.3f  onset=%d', ...
         frame.frame_number, frame.wall_seconds, ...
         frame.loudness, frame.centroid, frame.flatness, frame.onset);
  if ~isnan(frame.flux)
    printf('  flux=%.3f', frame.flux);
  end
  printf('\n');
  if frame.peak_count == 0
    printf('  (no peaks)\n');
  else
    for i = 1:frame.peak_count
      printf('  peak %d: %7.2f hz  mag=%.3f\n', ...
             i, frame.peaks(i,1), frame.peaks(i,2));
    end
  end
  if ~isempty(frame.pairs)
    printf('  ratios:\n');
    for i = 1:numel(frame.pairs)
      p = frame.pairs(i);
      printf('    %7.2f / %7.2f hz  ->  %d/%d  %4.0fc  strange=%.3f  [%s]\n', ...
             p.freq_high, p.freq_low, p.num, p.den, p.cents, ...
             p.strangeness, p.blend_name);
    end
  end
  fflush(stdout);
end
