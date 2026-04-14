function result = lattice(command, varargin)
% LATTICE  construct and navigate a just intonation lattice
%
% each prime defines an axis. a ratio's position in the lattice is its monzo
% (prime exponent vector). moving along the 3-axis means multiplying by 3/2.
% moving along the 5-axis means multiplying by 5/4. and so on for every prime.
%
% commands:
%
%   pos = lattice('position', num, den)
%     returns the lattice position (monzo) for ratio num/den
%
%   r = lattice('ratio', monzo)
%     converts a monzo back to [numerator, denominator]
%
%   d = lattice('taxicab', num1, den1, num2, den2)
%     taxicab distance between two ratios in lattice space
%     weighted by log2 of each prime (tenney-weighted)
%
%   neighbors = lattice('neighbors', num, den, prime_limit)
%     returns all ratios reachable by one step along any prime axis
%     up to the given prime limit. each row is [num, den]
%
%   tones = lattice('sublattice', prime_limit, max_exponent)
%     generates all lattice points within max_exponent steps on each axis
%     for primes up to prime_limit. returns matrix of [num, den, cents]
%
% examples:
%   lattice('position', 3, 2)           => [-1, 1]
%   lattice('ratio', [-1, 1])           => [3, 2]
%   lattice('taxicab', 3, 2, 5, 4)      => ~2.74
%   lattice('neighbors', 1, 1, 7)       => one step in each direction on 3,5,7 axes
%   lattice('sublattice', 5, 2)         => all 5-limit ratios within 2 steps

  switch command
    case 'position'
      result = prime_factorize(varargin{1}, varargin{2});

    case 'ratio'
      monzo = varargin{1};
      primes_list = primes(100);
      primes_list = primes_list(1:length(monzo));
      num = 1;
      den = 1;
      for i = 1:length(monzo)
        if monzo(i) > 0
          num = num * primes_list(i)^monzo(i);
        elseif monzo(i) < 0
          den = den * primes_list(i)^abs(monzo(i));
        end
      end
      result = [num, den];

    case 'taxicab'
      m1 = prime_factorize(varargin{1}, varargin{2});
      m2 = prime_factorize(varargin{3}, varargin{4});
      max_len = max(length(m1), length(m2));
      m1(end+1:max_len) = 0;
      m2(end+1:max_len) = 0;
      diff = m1 - m2;
      primes_list = primes(100);
      primes_list = primes_list(1:max_len);
      result = sum(abs(diff) .* log2(primes_list));

    case 'neighbors'
      num = varargin{1};
      den = varargin{2};
      plimit = varargin{3};
      axes = primes(plimit);
      % exclude prime 2 (octave equivalence)
      axes = axes(axes > 2);
      neighbors = [];
      for i = 1:length(axes)
        p = axes(i);
        % step up: multiply by p then reduce to one octave
        n_up = num * p;
        d_up = den;
        [n_up, d_up] = reduce_octave(n_up, d_up);
        neighbors = [neighbors; n_up, d_up];
        % step down: divide by p then reduce to one octave
        n_dn = num;
        d_dn = den * p;
        [n_dn, d_dn] = reduce_octave(n_dn, d_dn);
        neighbors = [neighbors; n_dn, d_dn];
      end
      result = neighbors;

    case 'sublattice'
      plimit = varargin{1};
      max_exp = varargin{2};
      axes = primes(plimit);
      axes = axes(axes > 2);
      n_axes = length(axes);
      % generate all combinations of exponents from -max_exp to +max_exp
      ranges = {};
      for i = 1:n_axes
        ranges{i} = -max_exp:max_exp;
      end
      grids = cell(1, n_axes);
      [grids{:}] = ndgrid(ranges{:});
      n_points = numel(grids{1});
      tones = [];
      for k = 1:n_points
        num = 1;
        den = 1;
        for i = 1:n_axes
          e = grids{i}(k);
          if e > 0
            num = num * axes(i)^e;
          elseif e < 0
            den = den * axes(i)^abs(e);
          end
        end
        [num, den] = reduce_octave(num, den);
        cents = 1200 * log2(num / den);
        tones = [tones; num, den, cents];
      end
      % sort by cents and remove duplicates
      tones = sortrows(tones, 3);
      [~, idx] = unique(round(tones(:,3) * 1000), 'stable');
      result = tones(idx, :);

    otherwise
      error('lattice: unknown command "%s"', command);
  end

end


function [n, d] = reduce_octave(n, d)
% bring ratio n/d into the range [1, 2)
  g = gcd(n, d);
  n = n / g;
  d = d / g;
  while n / d >= 2
    d = d * 2;
  end
  while n / d < 1
    n = n * 2;
  end
  g = gcd(n, d);
  n = n / g;
  d = d / g;
end
