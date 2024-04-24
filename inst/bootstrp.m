% Bootstrap resampling.
%
%
% -- Function File: BOOTSTAT = bootstrp (NBOOT, BOOTFUN, D)
% -- Function File: BOOTSTAT = bootstrp (NBOOT, BOOTFUN, D1, ..., DN)
% -- Function File: BOOTSTAT = bootstrp (..., 'Options', PAROPT)
% -- Function File: BOOTSTAT = bootstrp (..., 'Weights', WEIGHTS)
% -- Function File: BOOTSTAT = bootstrp (..., 'seed', SEED)
% -- Function File: BOOTSTAT = bootstrp (..., 'loo', LOO)
% -- Function File: BOOTSTAT = bootstrp (..., D1, ..., DN, 'match', MATCH)
% -- Function File: [BOOTSTAT, BOOTSAM] = bootstrp (...) 
%
%     'BOOTSTAT = bootstrp (NBOOT, BOOTFUN, D)' draws NBOOT bootstrap resamples
%     with replacement from the rows of the data D and returns the statistic
%     computed by BOOTFUN in BOOTSTAT [1]. BOOTFUN is a function handle (e.g.
%     specified with @) or name, a string indicating the function name, or a
%     cell array, where the first cell is one of the above function definitions
%     and the remaining cells are (additional) input arguments to that function
%     (after the data argument(s)). The third input argument is the data
%     (column vector, matrix or cell array), which is supplied to BOOTFUN. The
%     simulation method used by default is bootstrap resampling with first order
%     balance [2-3].
%
%     'BOOTSTAT = bootstrp (NBOOT, BOOTFUN, D1,...,DN)' is as above except that 
%     the third and subsequent input arguments are data are used to create
%     inputs for BOOTFUN.
%
%     'BOOTSTAT = bootstrp (..., 'Options', PAROPT)' specifies options that
%     govern if and how to perform bootstrap iterations using multiple
%     processors (if the Parallel Computing Toolbox or Octave Parallel package).
%     is available This argument is a structure with the following recognised
%     fields:
%        o 'UseParallel':  If true, use parallel processes to accelerate
%                          bootstrap computations on multicore machines. 
%                          Default is false for serial computation. In MATLAB,
%                          the default is true if a parallel pool
%                          has already been started. 
%        o 'nproc':        nproc sets the number of parallel processes
%
%     'BOOTSTAT = bootstrp (..., D1, ..., DN, 'match', MATCH)' controls the
%     resampling strategy when multiple data arguments are provided. When MATCH
%     is true, row indices of D1 to DN are the same (i.e. matched) for each
%     resample. This is the default strategy when D1 to DN all have the same
%     number of rows. If MATCH is set to false, then row indices are resampled
%     indpendently for D1 to DN in each of the resamples. When any of the data
%     D1 to DN, have a different number of rows, this input argument is ignored
%     and MATCH is enforced to have a value of false.
%
%     'BOOTSTAT = bootstrp (..., D, 'weights', WEIGHTS)' sets the resampling
%     weights. WEIGHTS must be a column vector with the same number of rows as
%     the data, D. If WEIGHTS is empty or not provided, the default is a vector
%     of length N with uniform weighting 1/N. 
%
%     'BOOTSTAT = bootstrp (..., D1, ... DN, 'weights', WEIGHTS)' as above if
%     MATCH is true. If MATCH is false, a 1-by-N cell array of column vectors
%     can be provided to specify independent resampling weights for D1 to DN.
%
%     'BOOTSTAT = bootstrp (..., 'loo', LOO)' sets the simulation method. If 
%     LOO is false, the resampling method used is balanced bootstrap resampling.
%     If LOO is true, the resampling method used is balanced bootknife
%     resampling [4]. The latter involves creating leave-one-out jackknife
%     samples of size N - 1, and then drawing resamples of size N with
%     replacement from the jackknife samples, thereby incorporating Bessel's
%     correction into the resampling procedure. LOO must be a scalar logical
%     value. The default value of LOO is false.
%
%     'BOOTSTAT = bootstrp (..., 'seed', SEED)' initialises the Mersenne Twister
%     random number generator using an integer SEED value so that bootci results
%     are reproducible.
%
%     '[BOOTSTAT, BOOTSAM] = bootstrp (...)' also returns indices used for
%     bootstrap resampling. If MATCH is true or only one data argument is
%     provided, BOOTSAM is a matrix. If multiple data arguments are provided
%     and MATCH is false, BOOTSAM is returned in a 1-by-N cell array of
%     matrices, where each cell corresponds to the respective data argument
%     D1 to DN.
%
%  Bibliography:
%  [1] Efron, and Tibshirani (1993) An Introduction to the
%        Bootstrap. New York, NY: Chapman & Hall
%  [2] Davison et al. (1986) Efficient Bootstrap Simulation.
%        Biometrika, 73: 555-66
%  [3] Booth, Hall and Wood (1993) Balanced Importance Resampling
%        for the Bootstrap. The Annals of Statistics. 21(1):286-298
%  [4] Hesterberg T.C. (2004) Unbiasing the Bootstrap—Bootknife Sampling 
%        vs. Smoothing; Proceedings of the Section on Statistics & the 
%        Environment. Alexandria, VA: American Statistical Association.
%
%  bootstrp (version 2024.04.23)
%  Author: Andrew Charles Penn
%  https://www.researchgate.net/profile/Andrew_Penn/
%
%  Copyright 2019 Andrew Charles Penn
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see http://www.gnu.org/licenses/


function [bootstat, bootsam] = bootstrp (argin1, argin2, varargin)

  % Evaluate the number of function arguments
  if (nargin < 2)
    error (cat (2, 'bootstrp usage: ''bootstrp (nboot, {bootfun, data},', ...
                   ' varargin)''; atleast 2 input arguments required'))
  end
  if (nargout > 2)
    error (cat (2, 'bootstrp: Maximum of 2 output arguments can be requested'))
  end

  % Store subfunctions in a stucture to make them available for parallel processes
  parsubfun = struct ('booteval', @booteval);

  % Check if using MATLAB or Octave
  info = ver; 
  ISOCTAVE = any (ismember ({info.Name}, 'Octave'));

  % Apply defaults
  paropt = struct;
  paropt.UseParallel = false;
  if (~ ISOCTAVE)
    ncpus = feature ('numcores');
  else
    ncpus = nproc;
  end
  paropt.nproc = ncpus;
  w = [];
  loo = false;
  match = true;
  seed = [];

  % Assign input arguments to function variables
  nboot = argin1;
  bootfun = argin2;
  argin3 = varargin;
  narg = numel (argin3);
  if (narg > 1)
    name = argin3{end - 1};
    value = argin3{end};
    while (ischar (name))
      switch (lower (name))
        case {'weights', 'weight'}
          w = value;
        case {'options', 'option'}
          paropt = value;
        case 'match'
          match = value;
        case 'seed'
          seed = value;
          boot (1, 1, false, seed); % Initialise the RNG with seed
        case 'loo'
          loo = value;
        otherwise
          error ('bootstrp: Unrecognised input argument to bootstrp')
      end
      argin3 = argin3(1:end-2);
      narg = numel (argin3);
      if (narg < 2)
        break
      end
      name = argin3{end - 1};
      value = argin3{end};
    end
  end
  x = argin3;
  if (paropt.UseParallel)
    if (isfield (paropt, 'nproc'))
      ncpus = paropt.nproc;
    else
      if (ISOCTAVE)
        ncpus = inf;
      else
        ncpus = [];
      end
    end
  else
    ncpus = 0;
  end

  % Error checking
  % nboot input argument
  if ((nargin < 2) || isempty (nboot))
    nboot = 1999;
  else
    if (~ isa (nboot, 'numeric'))
      error ('bootstrp: NBOOT must be numeric');
    end
    if (numel (nboot) > 1)
      error ('bootstrp: NBOOT cannot contain more than 1 value');
    end
    if (nboot ~= abs (fix (nboot)))
      error ('bootstrp: NBOOT must contain positive integers');
    end    
  end
  if (~ all (size (nboot) == [1, 1]))
    error ('bootstrp: NBOOT must be a scalar value')
  end

  % If applicable, check we have parallel computing capabilities
  if (ncpus > 1)
    if (ISOCTAVE)
      pat = '^parallel';
      software = pkg ('list');
      names = cellfun (@(S) S.name, software, 'UniformOutput', false);
      status = cellfun (@(S) S.loaded, software, 'UniformOutput', false);
      index = find (~ cellfun (@isempty, regexpi (names,pat)));
      if (~ isempty (index))
        if (logical (status{index}))
          PARALLEL = true;
        else
          PARALLEL = false;
        end
      else
        PARALLEL = false;
      end
    else
      info = ver; 
      if (ismember ('Parallel Computing Toolbox', {info.Name}))
        PARALLEL = true;
      else
        PARALLEL = false;
      end
    end
  end

  % If applicable, setup a parallel pool (required for MATLAB)
  if (~ ISOCTAVE)
    % MATLAB
    % bootfun is not vectorized
    if (ncpus > 0) 
      % MANUAL
      try 
        pool = gcp ('nocreate'); 
        if isempty (pool)
          if (ncpus > 1)
            % Start parallel pool with ncpus workers
            parpool (ncpus);
          else
            % Parallel pool is not running and ncpus is 1 so run function
            % evaluations in serial
            ncpus = 1;
          end
        else
          if (pool.NumWorkers ~= ncpus)
            % Check if number of workers matches ncpus and correct it
            % accordingly if not
            delete (pool);
            if (ncpus > 1)
              parpool (ncpus);
            end
          end
        end
      catch
        % MATLAB Parallel Computing Toolbox is not installed
        warning ('bootstrp:parallel', ...
                 cat (2, 'Parallel Computing Toolbox not installed or', ...
                         ' operational. Falling back to serial processing.'))
        ncpus = 1;
      end
    end
  else
    if ((ncpus > 1) && ~ PARALLEL)
      if (ISOCTAVE)
        % OCTAVE Parallel Computing Package is not installed or loaded
        warning ('bootstrp:parallel', ...
                 cat (2, 'Parallel package is not installed and/or loaded.', ...
                         ' Falling back to serial processing.'))
      else
        % MATLAB Parallel Computing Toolbox is not installed or loaded
        warning ('bootstrp:parallel', ...
                 cat (2, 'Parallel Computing Toolbox not installed and/or', ...
                         ' loaded. Falling back to serial processing.'))
      end
      ncpus = 0;
    end
  end

  % Determine properties of the data (x)
  n = cellfun (@(x) size (x, 1), x, 'UniformOutput', false);
  nvar = numel (n);
  if (nvar > 1)
    if  (~ isequal (n{:}))
      if (match)
        warning (cat (2, 'bootstrp: Data arguments do not have the same', ...
                         ' number of rows. Enforcing MATCH = false.'))
        match = false;
      end
    end
  end

  % bootfun input argument
  if ((nargin > 2) && (~ isempty (bootfun)))
    if (iscell (bootfun))
      if (ischar (bootfun{1}))
        % Convert character string of a function name to a function handle
        func = str2func (bootfun{1});
      else
        func = bootfun{1};
      end
      args = bootfun(2:end);
      bootfun = @(varargin) func (varargin{:}, args{:});
    elseif (ischar (bootfun))
      % Convert character string of a function name to a function handle
      bootfun = str2func (bootfun);
    elseif (isa (bootfun, 'function_handle'))
      % Do nothing
    else
      error ('bootstrp: BOOTFUN must be a function name or function handle')
    end
  end
  try
    t0 = bootfun (x{:});
  catch
    error (cat (2, 'bootstrp: There was an error evaluating ''bootfun''', ...
                   ' and the data provided'))
  end
  % Check whether evaluation of bootfun on the data is vectorized
  vectorized = false;
  if (eq (size (t0, 2), 1)) 
    if (all (bsxfun (@eq, 1, cellfun (@(x) size (x, 2), x))))
      xt = arrayfun (@(v) repmat (x{v}, 1, 2), 1 : nvar, 'UniformOutput', false);
      try
        chk = bootfun (xt{:});
        if ( eq (size (chk), cat (2, size (t0, 1), 2)) )
          vectorized = true;
        end
      catch
        % Do nothing
      end
    end
  end

  % Evaluate weights argument and convert each set of sampling probabilities to
  % a weighting vector that sums to N * NBOOT
  if (isempty (w))
    w = cellfun (@(n) ones (n, 1) / n, n, 'UniformOutput', false);
    s = num2cell (ones (1, nvar), 1);
  else
    if (isnumeric (w))
      w = repmat (mat2cell (w, n{1}, 1), 1, nvar);
    end
    if (any (arrayfun (@(v) any (bsxfun (@lt, w{v}, 0)), 1 : nvar)))
      error ('bootstrp: Weights cannot contain negative values')
    end
    if (any (arrayfun (@(v) any (isinf(w{v})), 1 : nvar)))
      error ('bootstrp: Weights cannot contain any infinite values')
    end
    if (any (arrayfun (@(v) any (isnan(w{v})), 1 : nvar)))
      error ('bootstrp: Weights cannot contain NaN values')
    end
    if (match)
      if (numel (w) > 1)
        if (~ isequal (w{:}))
          error (cat (2, 'bootstrp: Weights must be the same for each row', ...
                          ' of matching data sets'))
        end
      end
    else
      if (~ all (bsxfun (@eq, cat (2, 1, nvar), size (w))))
        error (cat (2, 'bootstrp: Weights must be an array of cells equal ', ...
                       ' equal in number to their non-matching data arguments'))
      end
    end
    s = arrayfun (@(v) fzero (@(s) sum (round (s * w{v} / mean (w{v}) * nboot) ...
                                - nboot), 1), 1 : nvar, 'UniformOutput', false);
  end
  w = arrayfun (@(v) round (s{v} * w{v} / mean (w{v}) * nboot), ...
                            1 : nvar, 'UniformOutput', false);

  % Perform balanced bootstrap resampling
  if (match)
    bootsam = repmat (mat2cell (boot (n{1}, nboot, loo, seed, w{1}), ...
                                n{1}, nboot), nvar, 1);
  else
    bootsam = cellfun (@(n, w) boot (n, nboot, loo, seed, w), ... 
                         n', w', 'UniformOutput', false);
  end
  if (isempty (bootfun))
    bootstat = zeros (nboot, 0);
  else
    if (ncpus > 1)
      % Parallel processing
      if (ISOCTAVE)
        % OCTAVE
        bootstat = parcellfun (ncpus, ...
                           @(i) parsubfun.booteval (x, i, bootfun, n, nvar), ...
                                           num2cell (cell2mat (bootsam), 1), ...
                                           'UniformOutput', false);
      else
        % MATLAB
        parbootsam = num2cell (cell2mat (bootsam), 1);
        bootstat = cell (1, nboot);
        parfor b = 1:nboot 
          bootstat{b} = booteval (x, parbootsam{b}, bootfun, n, nvar);
        end
      end
    else
      % Serial processing
      if (vectorized)
        % Fast: Vectorized evaluation of bootfun on the resampled
        XR = arrayfun (@(v) x{v}(bootsam{v}), 1 : nvar, 'UniformOutput', false);
        bootstat = num2cell (bootfun (XR{:}), 2);
      else
        % Slow: Looped evaluation of bootfun on the resampled
        bootstat = cellfun (@(i) booteval (x, i, bootfun, n, nvar), ...
                                 num2cell (cell2mat (bootsam), 1), ...
                                 'UniformOutput', false);
      end
    end
    bootstat = [bootstat{:}]';
  end
  if (match)
    bootsam(2:end) = [];
    bootsam = cell2mat (bootsam);
  else
    bootsam = bootsam';
  end

end

%--------------------------------------------------------------------------

function bootstat = booteval (x, bootsam, bootfun, n, nvar)

    % Helper subfunction to resample x using bootsam and evaluate bootfun
    i = mat2cell (bootsam, cell2mat (n));
    xr = arrayfun (@(v) x{v}(i{v}, :), 1 : nvar, 'UniformOutput', false);
    bootstat = reshape (bootfun (xr{:}), [], 1);

end

%!demo
%!
%! % Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41]';
%!
%! % Compute 50 bootstrap statistics for the mean and calculate the bootstrap
%! % standard error
%! bootstat = bootstrp (50, @mean, data)
%! std (bootstat)

%!test
%!
%! % Input test dataset
%! X = [212 435 339 251 404 510 377 335 410 335 ...
%!      415 356 339 188 256 296 249 303 266 300]';
%! Y = [247 461 526 302 636 593 393 409 488 381 ...
%!      474 329 555 282 423 323 256 431 437 240]';
%! Z = cat (1, X, Y);
%!
%! bootstrp (50, @mean, X);
%! bootstrp (50, @(x) mean (cell2mat (x)), num2cell (X, 2));
%! bootstrp (50, @(x, y) mean (x) - mean (y), X, Y);
%! bootstrp (50, @(x, y) mean (x - y), X, Y);
%! bootstrp (50, @(x, y) mean (x - y), X, Y, 'match', true);
%! bootstrp (50, @(x, y) mean (x) - mean (y), X, Y, 'match', false);
%! bootstrp (50, @(x, z) mean (x) - mean (z), X, Z, 'match', false);
%! bootstrp (50, @var, X);
%! bootstrp (50, {@var, 1}, X);
%! bootstrp (50, @cor, X, Y);
%! bootstrp (50, {@cor,'squared'}, X, Y);
%! bootstrp (50, @(x, y) cor (cell2mat (x), cell2mat (y)), num2cell (X, 2), ...
%!                                                         num2cell (Y, 2));
%! bootstrp (50, @mldivide, X, Y);
%! bootstrp (50, @mldivide, cat (2, ones (20, 1), X), Y);
%! bootstrp (50, @(x, y) mldivide (x, cell2mat (y)), ...
%!                          cat (2, ones (20, 1), X), num2cell (Y, 2));
%! bootstrp (50, @mean, X, 'seed', 1);
%! bootstrp (50, @mean, X, 'loo', false);
%! bootstrp (50, @mean, X, 'Weights', rand (20, 1));
%! bootstrp (50, @mean, X, 'seed', 1, 'loo', false, 'Weights', rand (20, 1));

