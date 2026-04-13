function result = affect(command, varargin)
% AFFECT  compute the affective character of a just intonation interval
%         based on its prime content
%
% primes get stranger toward infinity. 2 is transparent. 3 is powerful.
% 5 is sweet. 7 is bluesy. 11 is alien. 13 is uncanny. beyond that
% the floor drops out and you are in territory that no tuning system
% in common use has mapped.
%
% this function does not pretend to measure consonance or dissonance.
% those are culturally contingent and historically shifting boundaries.
% what it measures is STRANGENESS — how far from the familiar harmonic
% world a ratio sits based on which primes it touches and how deeply.
%
% commands:
%
%   s = affect('strangeness', num, den)
%     returns a value in [0, 1) where 0 is maximally familiar (unison)
%     and the value approaches 1 as prime content grows toward infinity.
%     uses 1 - 1/log2(tenney_height) scaled so that simple intervals
%     cluster near 0 and high-prime intervals push toward 1.
%
%   p = affect('prime_character', num, den)
%     returns a struct with fields:
%       .highest_prime   — the largest prime factor
%       .prime_factors   — list of all prime factors present
%       .strangeness     — the strangeness value
%       .monzo           — the prime exponent vector
%       .description     — a text description of the prime character
%
%   v = affect('strangeness_vector', num, den)
%     returns per-prime strangeness contributions as a vector.
%     each element is |exponent| * log2(prime) / total_tenney_height.
%     shows which primes dominate the intervals character.
%
% examples:
%   affect('strangeness', 3, 2)          => ~0.42  (familiar)
%   affect('strangeness', 7, 4)          => ~0.58  (getting strange)
%   affect('strangeness', 11, 8)         => ~0.69  (alien)
%   affect('strangeness', 13, 8)         => ~0.72  (uncanny)
%   affect('prime_character', 7, 4)      => struct with description

  switch command
    case 'strangeness'
      num = varargin{1};
      den = varargin{2};
      g = gcd(num, den);
      num = num / g;
      den = den / g;
      if num == den
        result = 0;
        return;
      end
      th = log2(num * den);
      % asymptotically approach 1 as tenney height grows
      result = 1 - 1 / (1 + log2(th));

    case 'prime_character'
      num = varargin{1};
      den = varargin{2};
      g = gcd(num, den);
      num = num / g;
      den = den / g;
      monzo = prime_factorize(num, den);
      primes_list = primes(100);
      primes_list = primes_list(1:length(monzo));

      % find primes actually present
      active = primes_list(monzo ~= 0);
      if isempty(active)
        hp = 1;
      else
        hp = max(active);
      end

      result.highest_prime = hp;
      result.prime_factors = active;
      result.strangeness = affect('strangeness', varargin{1}, varargin{2});
      result.monzo = monzo;
      result.description = describe_prime(hp);

    case 'strangeness_vector'
      num = varargin{1};
      den = varargin{2};
      g = gcd(num, den);
      num = num / g;
      den = den / g;
      monzo = prime_factorize(num, den);
      primes_list = primes(100);
      primes_list = primes_list(1:length(monzo));
      weights = abs(monzo) .* log2(primes_list);
      total = sum(weights);
      if total == 0
        result = zeros(size(monzo));
      else
        result = weights / total;
      end

    otherwise
      error('affect: unknown command "%s"', command);
  end

end


function desc = describe_prime(p)
% describe the character of a prime number in just intonation
% these are not opinions. these are accumulated observations from
% partch johnston gann young and a century of just intonation practice.
  switch p
    case 1
      desc = 'unison. identity. silence before sound.';
    case 2
      desc = 'octave. transparent. the same note in a different register.';
    case 3
      desc = 'power. open fifths and fourths. medieval stone.';
    case 5
      desc = 'sweetness. major and minor thirds. the warmth of common practice harmony.';
    case 7
      desc = 'blue. the septimal world. barbershop angels and delta mud.';
    case 11
      desc = 'alien. neutral intervals. neither major nor minor. the 11th harmonic falls between the keys.';
    case 13
      desc = 'uncanny. deeper than alien. gann said it took him years to learn to hear it.';
    case 17
      desc = 'a strange return. 17 approximates a semitone. the familiar seen from far away.';
    case 19
      desc = 'another false familiar. 19 approximates a minor third. an echo of 5 through a distant wall.';
    otherwise
      if p <= 1
        desc = 'not a prime.';
      else
        desc = sprintf('prime %d. beyond the mapped territory. ominous. approaching infinity.', p);
      end
  end
end
