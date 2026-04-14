function result = blend(command, varargin)
% BLEND  compute the combined affective character when multiple primes
%        meet inside a single ratio
%
% a ratio like 3/2 touches one prime above the octave. simple.
% a ratio like 15/8 touches two primes (3 and 5). the affect is
% a mixture. power meets sweetness. the character is neither
% pure 3 nor pure 5 but something born from their collision.
%
% the deeper into composite territory you go the more primes
% overlap and the stranger the brew gets. 385/256 touches 5 7 and 11
% simultaneously. sweetness and blue and alien in one interval.
% no single prime dominates. the affect is emergent.
%
% commands:
%
%   b = blend('character', num, den)
%     returns a struct describing the composite affect:
%       .primes          list of active primes (above 2)
%       .weights         how much each prime contributes (0 to 1)
%       .dominant        the prime with the most weight
%       .recessive       the prime with the least weight
%       .depth           how many distinct primes above 2
%       .descriptions    cell array of per-prime descriptions
%       .blend_name      a generated name for the combination
%       .strangeness     overall strangeness from affect()
%
%   n = blend('name', num, den)
%     returns just the blend name as a string
%
%   m = blend('mix', num, den)
%     returns a vector of [prime, weight] pairs sorted by weight
%     descending. only primes above 2 with nonzero exponents.
%
% examples:
%   blend('character', 15, 8)    3 and 5. power-sweetness.
%   blend('character', 21, 16)   3 and 7. power-blue.
%   blend('character', 35, 32)   5 and 7. sweet-blue.
%   blend('character', 385, 256) 5 7 11. sweet-blue-alien.
%   blend('character', 7, 4)     just 7. pure blue. no blend.
%   blend('name', 15, 8)         => 'power-sweetness'

  switch command
    case 'character'
      num = varargin{1};
      den = varargin{2};
      result = compute_character(num, den);

    case 'name'
      num = varargin{1};
      den = varargin{2};
      ch = compute_character(num, den);
      result = ch.blend_name;

    case 'mix'
      num = varargin{1};
      den = varargin{2};
      ch = compute_character(num, den);
      if isempty(ch.primes)
        result = [];
      else
        result = sortrows([ch.primes(:), ch.weights(:)], -2);
      end

    otherwise
      error('blend: unknown command "%s"', command);
  end

end


function ch = compute_character(num, den)
  monzo = prime_factorize(num, den);
  primes_list = primes(100);
  primes_list = primes_list(1:length(monzo));

  % only care about primes above 2
  mask = (primes_list > 2) & (monzo ~= 0);
  active_primes = primes_list(mask);
  active_exponents = abs(monzo(mask));

  % weight by exponent * log2(prime) same as strangeness_vector
  if isempty(active_primes)
    ch.primes = [];
    ch.weights = [];
    ch.dominant = 2;
    ch.recessive = 2;
    ch.depth = 0;
    ch.descriptions = {'octave. transparent.'};
    ch.blend_name = 'transparent';
    ch.strangeness = affect('strangeness', num, den);
    return;
  end

  raw_weights = active_exponents .* log2(active_primes);
  total = sum(raw_weights);
  if total == 0
    weights = zeros(size(raw_weights));
  else
    weights = raw_weights / total;
  end

  [~, imax] = max(weights);
  [~, imin] = min(weights);

  ch.primes = active_primes;
  ch.weights = weights;
  ch.dominant = active_primes(imax);
  ch.recessive = active_primes(imin);
  ch.depth = length(active_primes);
  ch.strangeness = affect('strangeness', num, den);

  % per prime descriptions
  descs = {};
  for i = 1:length(active_primes)
    descs{end+1} = prime_flavor(active_primes(i));
  end
  ch.descriptions = descs;

  % build the blend name
  if ch.depth == 1
    ch.blend_name = sprintf('pure %s', prime_flavor(active_primes(1)));
  else
    names = {};
    % sort by weight descending for name ordering
    [~, order] = sort(weights, 'descend');
    for i = 1:length(order)
      names{end+1} = prime_flavor(active_primes(order(i)));
    end
    ch.blend_name = strjoin(names, '-');
  end
end


function f = prime_flavor(p)
% one word flavor for each prime. these are the pigments.
% when you blend them you get the composite color.
  switch p
    case 2
      f = 'transparent';
    case 3
      f = 'power';
    case 5
      f = 'sweetness';
    case 7
      f = 'blue';
    case 11
      f = 'alien';
    case 13
      f = 'uncanny';
    case 17
      f = 'echo';
    case 19
      f = 'ghost';
    case 23
      f = 'void';
    case 29
      f = 'rust';
    case 31
      f = 'static';
    case 37
      f = 'vertigo';
    case 41
      f = 'fog';
    case 43
      f = 'ash';
    case 47
      f = 'thorn';
    case 53
      f = 'smoke';
    case 59
      f = 'salt';
    case 61
      f = 'bone';
    case 67
      f = 'mercury';
    case 71
      f = 'obsidian';
    case 73
      f = 'amber';
    case 79
      f = 'iron';
    case 83
      f = 'sulfur';
    case 89
      f = 'glass';
    case 97
      f = 'lead';
    otherwise
      f = sprintf('prime%d', p);
  end
end
