function result = heterodyne(command, varargin)
% HETERODYNE  compute combination tone products from two frequencies
%
% when two frequencies pass through any nonlinear system (the cochlea,
% a distorting amplifier, the air column of a brass instrument) they
% produce new frequencies at m*f1 +/- n*f2 for all integer m and n.
% these are heterodyne products. combination tones. tartini tones.
%
% the key insight for just intonation: if f1 and f2 are related by a
% just ratio p:q then EVERY combination tone is an exact integer
% multiple of the implied fundamental f0 = f1/p = f2/q.
% this is not an approximation. it is arithmetic.
% in equal temperament the products are irrational and they beat.
%
% commands:
%
%   tones = heterodyne('products', f1, f2, max_order)
%     returns all combination tone frequencies up to the given order.
%     each row is [frequency, m, n, order, sign] where sign is +1 or -1
%     for sum or difference. sorted by frequency. duplicates removed.
%
%   tones = heterodyne('products_ji', num, den, f1, max_order)
%     same as products but for a just interval. f1 is the lower frequency.
%     f2 is computed from the ratio. each row adds a 6th column: the
%     harmonic number relative to the implied fundamental.
%
%   h = heterodyne('harmonicity', num, den, max_order)
%     returns 1.0 if all products through max_order land on exact
%     harmonics of the implied fundamental (always true for just ratios).
%     for tempered intervals pass approximate num/den and this returns
%     the fraction of products within 1 cent of a harmonic.
%
%   fund = heterodyne('implied_fundamental', f1, f2, num, den)
%     returns the implied fundamental frequency f0 = f1 / num = f2 / den
%
% examples:
%   heterodyne('products', 200, 300, 3)
%     => all combination tones of a 3:2 fifth through 3rd order
%
%   heterodyne('products_ji', 3, 2, 200, 3)
%     => same but with harmonic numbers relative to f0 = 100 hz
%
%   heterodyne('implied_fundamental', 200, 300, 3, 2)
%     => 100

  switch command
    case 'products'
      f1 = varargin{1};
      f2 = varargin{2};
      max_order = varargin{3};
      result = compute_products(f1, f2, max_order);

    case 'products_ji'
      num = varargin{1};
      den = varargin{2};
      f1 = varargin{3};
      max_order = varargin{4};
      f2 = f1 * num / den;
      products = compute_products(f1, f2, max_order);
      f0 = f1 / den;
      harmonics = round(products(:, 1) / f0);
      result = [products, harmonics];

    case 'harmonicity'
      num = varargin{1};
      den = varargin{2};
      max_order = varargin{3};
      f1 = 1000;
      f2 = f1 * num / den;
      f0 = f1 / den;
      products = compute_products(f1, f2, max_order);
      freqs = products(:, 1);
      harmonic_nums = freqs / f0;
      deviations_cents = abs(1200 * log2(harmonic_nums ./ round(harmonic_nums)));
      % handle exact zeros
      deviations_cents(isnan(deviations_cents)) = 0;
      n_close = sum(deviations_cents < 1.0);
      result = n_close / length(freqs);

    case 'implied_fundamental'
      f1 = varargin{1};
      f2 = varargin{2};
      num = varargin{3};
      den = varargin{4};
      result = f1 / den;

    otherwise
      error('heterodyne: unknown command "%s"', command);
  end

end


function products = compute_products(f1, f2, max_order)
% generate all combination tone products up to max_order
% returns matrix of [frequency, m, n, order, sign]
  rows = [];
  for order = 2:max_order
    for m = 0:order
      n = order - m;
      % sum tone
      f_sum = m * f1 + n * f2;
      if f_sum > 0
        rows = [rows; f_sum, m, n, order, 1];
      end
      % difference tone
      f_diff = abs(m * f1 - n * f2);
      if f_diff > 0
        rows = [rows; f_diff, m, n, order, -1];
      end
    end
  end

  if isempty(rows)
    products = [];
    return;
  end

  % remove duplicates by frequency (within 0.001 hz tolerance)
  rows = sortrows(rows, 1);
  keep = true(size(rows, 1), 1);
  for i = 2:size(rows, 1)
    if abs(rows(i, 1) - rows(i-1, 1)) < 0.001
      % keep the lower order one
      if rows(i, 4) > rows(i-1, 4)
        keep(i) = false;
      else
        keep(i-1) = false;
      end
    end
  end
  products = rows(keep, :);
end
