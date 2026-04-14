function monzo = prime_factorize(num, den)
% PRIME_FACTORIZE  decompose a frequency ratio into its monzo representation
%
% monzo = prime_factorize(num, den)
%
% a monzo is a vector of prime exponents. the ratio 3/2 = 2^(-1) * 3^(1)
% gives monzo [-1, 1]. the ratio 7/4 = 2^(-2) * 7^(1) gives [-2, 0, 0, 1].
%
% the vector length equals the number of primes up to and including the
% largest prime factor found in either num or den.
%
% examples:
%   prime_factorize(3, 2)   => [-1, 1]
%   prime_factorize(5, 4)   => [-2, 0, 1]
%   prime_factorize(7, 4)   => [-2, 0, 0, 1]
%   prime_factorize(11, 8)  => [-3, 0, 0, 0, 1]
%   prime_factorize(15, 8)  => [-3, 1, 1]

  g = gcd(num, den);
  num = num / g;
  den = den / g;

  max_val = max(num, den);
  primes_list = primes(max_val);

  if isempty(primes_list)
    monzo = [];
    return;
  end

  monzo = zeros(1, length(primes_list));

  for i = 1:length(primes_list)
    p = primes_list(i);
    while mod(num, p) == 0
      monzo(i) = monzo(i) + 1;
      num = num / p;
    end
    while mod(den, p) == 0
      monzo(i) = monzo(i) - 1;
      den = den / p;
    end
  end

  % trim trailing zeros
  last_nonzero = find(monzo ~= 0, 1, 'last');
  if isempty(last_nonzero)
    monzo = [0];
  else
    monzo = monzo(1:last_nonzero);
  end

end
