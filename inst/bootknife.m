% -- Function File: bootknife (DATA)
% -- Function File: bootknife (DATA, NBOOT)
% -- Function File: bootknife (DATA, NBOOT, BOOTFUN)
% -- Function File: bootknife ({DATA}, NBOOT, BOOTFUN)
% -- Function File: bootknife (DATA, NBOOT, {BOOTFUN, ...})
% -- Function File: bootknife (DATA, NBOOT, ..., ALPHA)
% -- Function File: bootknife (DATA, NBOOT, ..., ALPHA, STRATA)
% -- Function File: bootknife (DATA, NBOOT, ..., ALPHA, STRATA, NPROC)
% -- Function File: bootknife (DATA, NBOOT, ..., ALPHA, STRATA, NPROC, BOOTSAM)
% -- Function File: STATS = bootknife (...)
% -- Function File: [STATS, BOOTSTAT] = bootknife (...)
% -- Function File: [STATS, BOOTSTAT] = bootknife (...)
% -- Function File: [STATS, BOOTSTAT, BOOTSAM] = bootknife (...)
%
%     'bootknife (DATA)' uses a variant of nonparametric bootstrap, called
%     bootknife [1], to generate 2000 resamples from the rows of the DATA
%     (column vector or matrix) and compute their means and display the
%     following statistics:
%        • original: the original estimate(s) calculated by BOOTFUN and the DATA
%        • bias: bootstrap bias of the estimate(s)
%        • std_error: bootstrap estandard error of the estimate(s)
%        • CI_lower: lower bound(s) of the 95% bootstrap confidence interval
%        • CI_upper: upper bound(s) of the 95% bootstrap confidence interval
%
%     'bootknife (DATA, NBOOT)' specifies the number of bootstrap resamples,
%     where NBOOT can be either:
%        • scalar: A positive integer specifying the number of bootstrap
%                  resamples [2,3] for single bootstrap, or
%        • vector: A pair of positive integers defining the number of outer and
%                  inner (nested) resamples for iterated (a.k.a. double)
%                  bootstrap and coverage calibration [3-6]. Be wary of extreme 
%                  corrections to the percentiles (i.e. to 0% or 100%), which
%                  can arise when sample sizes are small.
%        THe default value of NBOOT is the scalar: 2000.
%
%     'bootknife (DATA, NBOOT, BOOTFUN)' also specifies BOOTFUN: the function
%     calculated on the original sample and the bootstrap resamples. BOOTFUN
%     must be either a:
%        • function handle,
%        • string of function name, or
%        • a cell array where the first cell is one of the above function
%          definitions and the remaining cells are (additional) input arguments 
%          to that function (other than the data arguments).
%        In all cases BOOTFUN must take DATA for the initial input argument(s).
%        BOOTFUN can return a scalar or any multidimensional numeric variable,
%        but the output will be reshaped as a column vector. BOOTFUN must
%        calculate a statistic representative of the finite data sample; it
%        should NOT be an estimate of a population parameter (unless they are
%        one of the same). If BOOTFUN is @mean or 'mean', narrowness bias of
%        the confidence intervals for single bootstrap are reduced by expanding
%        the probabilities of the percentiles using Student's t-distribution
%        [7]. By default, BOOTFUN is @mean.
%
%     'bootknife ({D1, D2,...}, NBOOT, BOOTFUN)' resamples from the rows of D1,
%     D2 etc and the resamples are passed to BOOTFUN as multiple data input
%     arguments. All data vectors and matrices (D1, D2 etc) must have the same
%     number of rows.
%
%     'bootknife (..., NBOOT, BOOTFUN, ALPHA)', where ALPHA is numeric and
%     sets the lower and upper bounds of the confidence interval(s). The
%     value(s) of ALPHA must be between 0 and 1. ALPHA can either be:
%        • scalar: To set the (nominal) central coverage of equal-tailed
%                  percentile confidence intervals to 100*(1-ALPHA)%. The
%                  intervals are either simple percentiles for single
%                  bootstrap, or percentiles with calibrated central coverage 
%                  for double bootstrap.
%        • vector: A pair of probabilities defining the (nominal) lower and
%                  upper percentiles of the confidence interval(s) as
%                  100*(ALPHA(1))% and 100*(ALPHA(2))% respectively. The
%                  percentiles are either bias-corrected and accelerated (BCa)
%                  for single bootstrap, or calibrated for double bootstrap.
%        Note that the type of coverage calibration (i.e. equal-tailed or
%        not) depends on whether NBOOT is a scalar or a vector. Confidence
%        intervals are not calculated when the value(s) of ALPHA is/are NaN.
%        The default value of ALPHA is the vector: [.025, .975], for a 95%
%        confidence interval.
%
%     'bootknife (..., NBOOT, BOOTFUN, ALPHA, STRATA)' also sets STRATA, which
%     are identifiers that define the grouping of the DATA rows for stratified
%     bootstrap resampling. STRATA should be a column vector or cell array with
%     the same number of rows as the DATA. 
%
%     'bootknife (..., NBOOT, BOOTFUN, ALPHA, STRATA, NPROC)' also sets the
%     number of parallel processes to use to accelerate computations of double
%     bootstrap, jackknife and non-vectorized function evaluations on multicore
%     machines. This feature requires the Parallel package (in Octave), or the
%     Parallel Computing Toolbox (in Matlab).
%
%     'bootknife (..., NBOOT, BOOTFUN, ALPHA, STRATA, NPROC, BOOTSAM)' uses
%     bootstrap resampling indices provided in BOOTSAM. The BOOTSAM should be a
%     matrix with the same number of rows as the data. When BOOTSAM is provided,
%     the first element of NBOOT is ignored.
%
%     'STATS = bootknife (...)' returns a structure with the following fields
%     (defined above): original, bias, std_error, CI_lower, CI_upper.
%
%     '[STATS, BOOTSTAT] = bootknife (...)' returns BOOTSTAT, a vector or matrix
%     of bootstrap statistics calculated over the (first, or outer layer of)
%     bootstrap resamples.
%
%     '[STATS, BOOTSTAT, BOOTSAM] = bootknife (...)' also returns BOOTSAM, the
%     matrix of indices (32-bit integers) used for the (first, or outer
%     layer of) bootstrap resampling. Each column in BOOTSAM corresponds
%     to one bootstrap resample and contains the row indices of the values
%     drawn from the nonscalar DATA argument to create that sample.
%
%  REQUIREMENTS:
%    The function file boot.m (or better boot.mex) also distributed in the
%  statistics-bootstrap package.
%
%  DETAILS:
%    For a DATA sample with n rows, bootknife resampling involves creating
%  leave-one-out jackknife samples of size n - 1 and then drawing resamples
%  of size n with replacement from the jackknife samples [1]. In contrast
%  to bootstrap, bootknife resampling produces unbiased estimates of the
%  standard error of BOOTFUN when n is small. The resampling of DATA rows
%  is balanced in order to reduce Monte Carlo error, particularly for
%  estimating the bias of BOOTFUN [8,9].
%    For single bootstrap, the confidence intervals are constructed from the
%  quantiles of a kernel density estimate of the bootstrap statistics
%  (with shrinkage corrrection). 
%    For double bootstrap, calibration is used to improve the accuracy of the 
%  bias and standard error, and coverage of the confidence intervals [2-6]. 
%  Double bootstrap confidence intervals are constructed from the empirical
%  distribution of the bootstrap statistics by linear interpolation. 
%    This function has no input arguments for specifying a random seed. However,
%  one can reset the random number generator with a SEED value using following
%  command:
%
%  >> boot (1, 1, false, SEED);
%
%    Please see the help documentation for the function 'boot' for more
%  information about setting the seed for parallel execution of bootknife.
%
%  BIBLIOGRAPHY:
%  [1] Hesterberg T.C. (2004) Unbiasing the Bootstrap—Bootknife Sampling 
%        vs. Smoothing; Proceedings of the Section on Statistics & the 
%        Environment. Alexandria, VA: American Statistical Association.
%  [2] Davison A.C. and Hinkley D.V (1997) Bootstrap Methods And Their 
%        Application. (Cambridge University Press)
%  [3] Efron, and Tibshirani (1993) An Introduction to the
%        Bootstrap. New York, NY: Chapman & Hall
%  [4] Booth J. and Presnell B. (1998) Allocation of Monte Carlo Resources for
%        the Iterated Bootstrap. J. Comput. Graph. Stat. 7(1):92-112 
%  [5] Lee and Young (1999) The effect of Monte Carlo approximation on coverage
%        error of double-bootstrap con®dence intervals. J R Statist Soc B. 
%        61:353-366.
%  [6] Hall, Lee and Young (2000) Importance of interpolation when
%        constructing double-bootstrap confidence intervals. Journal
%        of the Royal Statistical Society. Series B. 62(3): 479-491
%  [7] Hesterberg, Tim (2014), What Teachers Should Know about the 
%        Bootstrap: Resampling in the Undergraduate Statistics Curriculum, 
%        http://arxiv.org/abs/1411.5279
%  [8] Davison et al. (1986) Efficient Bootstrap Simulation.
%        Biometrika, 73: 555-66
%  [9] Gleason, J.R. (1988) Algorithms for Balanced Bootstrap Simulations. 
%        The American Statistician. Vol. 42, No. 4 pp. 263-266
%
%  bootknife (version 2023.07.04)
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
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.


function [stats, bootstat, bootsam] = bootknife (x, nboot, bootfun, alpha, ...
                              strata, ncpus, bootsam, REF, ISOCTAVE, ERRCHK)

  % Input argument names in all-caps are for internal use only
  % REF, ISOCTAVE and ERRCHK are undocumented input arguments required
  % for some of the functionalities of bootknife

  % Store local functions in a stucture for parallel processes
  localfunc = struct ('col2args', @col2args, ...
                      'empcdf', @empcdf, ...
                      'kdeinv', @kdeinv, ...
                      'ExpandProbs', @ExpandProbs);

  % Set defaults and check for errors (if applicable)
  if ((nargin < 10) || isempty (ERRCHK) || ERRCHK)
    if (nargin < 1)
      error ('bootknife: DATA must be provided');
    end
    if ((nargin < 2) || isempty (nboot))
      nboot = [2000, 0];
    else
      if (~ isa (nboot, 'numeric'))
        error ('bootknife: NBOOT must be numeric');
      end
      if (numel (nboot) > 2)
        error ('bootknife: NBOOT cannot contain more than 2 values');
      end
      if (any (nboot ~= abs (fix (nboot))))
        error ('bootknife: NBOOT must contain positive integers');
      end    
      if (numel(nboot) == 1)
        nboot = [nboot, 0];
      end
    end
    if ((nargin < 3) || isempty (bootfun))
      bootfun = @mean;
      bootfun_str = 'mean';
    else
      if (iscell (bootfun))
        if (ischar (bootfun{1}))
          % Convert character string of a function name to a function handle
          bootfun_str = bootfun{1};
          func = str2func (bootfun{1});
        else
          bootfun_str = func2str (bootfun{1});
          func = bootfun{1};
        end
        args = bootfun(2:end);
        bootfun = @(varargin) func (varargin{:}, args{:});
      elseif (ischar (bootfun))
        % Convert character string of a function name to a function handle
        bootfun_str = bootfun;
        bootfun = str2func (bootfun);
      elseif (isa (bootfun, 'function_handle'))
        bootfun_str = func2str (bootfun);
      else
        error ('bootknife: BOOTFUN must be a function name or function handle')
      end
    end
    if (iscell (x))
      % If DATA is a cell array of equal size colunmn vectors, convert the cell
      % array to a matrix and redefine bootfun to parse multiple input arguments
      szx = cellfun (@(x) size (x,2), x);
      x = [x{:}];
      bootfun = @(x) localfunc.col2args (bootfun, x, szx);
    else
      szx = size (x, 2);
    end
    if (~ (size (x, 1) > 1))
      error ('bootknife: DATA must contain more than one row');
    end
    if ((nargin < 4) || isempty (alpha))
      alpha = [0.025, 0.975];
      nalpha = 2;
    else
      nalpha = numel (alpha);
      if (~ isa (alpha, 'numeric') || (nalpha > 2))
        error ('bootknife: ALPHA must be a scalar (two-tailed probability) or a vector (pair of probabilities)');
      end
      if (size (alpha, 1) > 1)
        alpha = alpha.';
      end
      if (any ((alpha < 0) | (alpha > 1)))
        error ('bootknife: Value(s) in ALPHA must be between 0 and 1');
      end
      if (nalpha > 1)
        % alpha is a pair of probabilities
        % Make sure probabilities are in the correct order
        if (alpha(1) > alpha(2) )
          error ('bootknife: The pair of probabilities must be in ascending numeric order');
        end
      end
    end
    if ((nargin < 5) || isempty (strata))
      strata = [];
    else  
      if (size (strata, 1) ~= size (x, 1))
        error ('bootknife: STRATA should be a column vector or cell array with the same number of rows as the DATA');
      end
    end
    if ((nargin < 6) || isempty (ncpus)) 
      ncpus = 0;    % Ignore parallel processing features
    else
      if (~ isa (ncpus, 'numeric'))
        error ('bootknife: NPROC must be numeric');
      end
      if (any (ncpus ~= abs (fix (ncpus))))
        error ('bootknife: NPROC must be a positive integer');
      end    
      if (numel (ncpus) > 1)
        error ('bootknife: NPROC must be a scalar value');
      end
    end
    if ((nargin < 9) || isempty (ISOCTAVE))
      % Check if running in Octave (else assume Matlab)
      info = ver; 
      ISOCTAVE = any (ismember ({info.Name}, 'Octave'));
    end
    if (ISOCTAVE)
      ncpus = min (ncpus, nproc);
    else
      ncpus = min (ncpus, feature ('numcores'));
    end
  else
    szx = 1;
  end

  % Determine properties of the DATA (x)
  [n, nvar] = size (x);
  if (n < 2)
    error ('bootknife: DATA must be numeric and contain > 1 row')
  end

  % Set number of outer and inner bootknife resamples
  B = nboot(1);
  if (numel (nboot) > 1)
    C = nboot(2);
  else
    C = 0;
  end

  % Evaluate bootfun on the DATA
  T0 = bootfun (x);
  if (any (isnan (T0)))
    error ('bootknife: BOOTFUN returned NaN with the DATA provided')
  end

  % Check whether bootfun is vectorized
  if (nvar > 1)
    M = cell2mat (cellfun (@(i) repmat (x(:, i), 1, 2), ...
                  num2cell (1:nvar), 'UniformOutput', false));
  else
    M = repmat (x, 1, 2);
  end
  if (any (szx > 1))
    vectorized = false;
  else
    try
      chk = bootfun (M);
      if (all (size (chk) == [size(T0, 1), 2]) && all (chk == bootfun (x)))
        vectorized = true;
      else
        vectorized = false;
      end
    catch
      vectorized = false;
    end
  end

  % Initialize probabilities
  l = [];

  % If applicable, check we have parallel computing capabilities
  if (ncpus > 1)
    if (ISOCTAVE)
      software = pkg ('list');
      names = cellfun (@(S) S.name, software, 'UniformOutput', false);
      status = cellfun (@(S) S.loaded, software, 'UniformOutput', false);
      index = find (~ cellfun (@isempty, regexpi (names, '^parallel')));
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
            % Parallel pool is not running and ncpus is 1 so run function evaluations in serial
            ncpus = 1;
          end
        else
          if (pool.NumWorkers ~= ncpus)
            % Check if number of workers matches ncpus and correct it accordingly if not
            delete (pool);
            if (ncpus > 1)
              parpool (ncpus);
            end
          end
        end
      catch
        % MATLAB Parallel Computing Toolbox is not installed
        warning ('bootknife:parallel', ...
           'Parallel Computing Toolbox not installed or operational. Falling back to serial processing.');
        ncpus = 1;
      end
    end
  else
    if ((ncpus > 1) && ~ PARALLEL)
      if (ISOCTAVE)
        % OCTAVE Parallel Computing Package is not installed or loaded
        warning ('bootknife:parallel', ...
          'Parallel Computing Package not installed and/or loaded. Falling back to serial processing.');
      else
        % MATLAB Parallel Computing Toolbox is not installed or loaded
        warning ('bootknife:parallel', ...
          'Parallel Computing Toolbox not installed and/or loaded. Falling back to serial processing.');
      end
      ncpus = 0;
    end
  end

  % Calculate the number of elements in the return value of bootfun 
  m = numel (T0);
  if (m > 1)
    % Vectorized along the dimension of the return values of bootfun so
    % reshape the output to be a column vector before proceeding with bootstrap
    if (size (T0, 2) > 1)
      bootfun = @(x) reshape (bootfun (x), [], 1);
      T0 = reshape (T0, [], 1);
      vectorized = false;
    end
  end

  % Evaluate strata input argument
  if (~ isempty (strata))
    if (~ isnumeric (strata))
      % Convert strata to numeric ID
      [jnk1, jnk2, strata] = unique (strata);
      clear jnk1 jnk2;
    end
    % Get strata IDs
    gid = unique (strata);  % strata ID
    K = numel (gid);        % number of strata
    % Create strata matrix
    g = cell2mat (cellfun (@(k) strata == gid(k), num2cell (1:K), 'UniformOutput', false));
    nk = sum (g);           % strata sample sizes
  else 
    g = ones (n, 1);
    K = 1;
  end

  % Perform balanced bootknife resampling
  unbiased = true;  % Set to true for bootknife resampling
  if ((nargin < 7) || isempty (bootsam))
    if (~ isempty (strata))
      if (nvar > 1) || (nargout > 2)
        % We can save some memory by making bootsam an int32 datatype
        bootsam = zeros (n, B, 'int32');
        for k = 1:K
          if ((sum (g(:, k))) > 1)
            bootsam(g(:, k), :) = boot (find (g(:, k)), B, unbiased);
          else
            bootsam(g(:, k), :) = find (g(:, k)) * ones (1, B);
          end
        end
      else
        % For more efficiency, if we don't need bootsam, we can directly resample values of x
        bootsam = [];
        X = zeros (n, B);
        for k = 1:K
          if ((sum (g(:, k))) > 1)
            X(g(:, k), :) = boot (x(g(:, k), :), B, unbiased);
          else
            X(g(:, k), :) = x(g(:, k), :) * ones (1, B);
          end
        end
      end
    else
      if (nvar > 1) || (nargout > 2)
        % We can save some memory by making bootsam an int32 datatype
        bootsam = zeros (n, B, 'int32');
        bootsam(:, :) = boot (n, B, unbiased);
      else
        % For more efficiency, if we don't need bootsam, we can directly resample values of x
        bootsam = [];
        X = boot (x, B, unbiased);
      end
    end
  else
    if (size (bootsam, 1) ~= n)
      error ('bootknife: BOOTSAM must have the same number of rows as X')
    end
    nboot(1) = size (bootsam, 2);
    B = nboot(1);
  end

  % Evaluate bootfun each bootstrap resample
  if (isempty (bootsam))
    if (vectorized)
      % Vectorized evaluation of bootfun on the DATA resamples
      bootstat = bootfun (X);
    else
      if (ncpus > 1)
        % Evaluate bootfun on each bootstrap resample in PARALLEL
        if (ISOCTAVE)
          % OCTAVE
          bootstat = parcellfun (ncpus, bootfun, num2cell (X, 1), 'UniformOutput', false);
        else
          % MATLAB
          bootstat = cell (1, B);
          parfor b = 1:B; bootstat{b} = bootfun (X(:, b)); end
        end
      else
        bootstat = cellfun (bootfun, num2cell (X, 1), 'UniformOutput', false);
      end
    end
  else
    if (vectorized)
      % DATA resampling (using bootsam) and vectorized evaluation of bootfun on 
      % the DATA resamples 
      if (nvar > 1)
        % Multivariate
        % Perform DATA sampling
        X = cell2mat (cellfun (@(i) reshape (x(bootsam, i), n, B), ...
                      num2cell (1:nvar, 1), 'UniformOutput', false));
      else
        % Univariate
        % Perform DATA sampling
        X = x(bootsam);
      end
      % Function evaluation on bootknife samples
      bootstat = bootfun (X);
    else 
      cellfunc = @(bootsam) bootfun (x(bootsam, :));
      if (ncpus > 1)
        % Evaluate bootfun on each bootstrap resample in PARALLEL
        if (ISOCTAVE)
          % OCTAVE
          bootstat = parcellfun (ncpus, cellfunc, num2cell (bootsam, 1), 'UniformOutput', false);
        else
          % MATLAB
          bootstat = cell (1, B);
          parfor b = 1:B; bootstat{b} = cellfunc (bootsam(:, b)); end
        end
      else
        % Evaluate bootfun on each bootstrap resample in SERIAL
        bootstat = cellfun (cellfunc, num2cell (bootsam, 1), 'UniformOutput', false);
      end
    end
  end
  if (iscell (bootstat))
    bootstat = cell2mat (bootstat);
  end
  
  % Remove bootstrap statistics that contain NaN, along with their associated 
  % DATA resamples in X or bootsam
  ridx = any (isnan (bootstat), 1);
  bootstat_all = bootstat;
  bootstat(:, ridx) = [];
  if (isempty (bootsam))
    X(:, ridx) = [];
  else
    bootsam(:, ridx) = [];
  end
  if (isempty (bootstat))
    error ('bootknife: BOOTFUN returned NaN for every bootstrap resample')
  end
  B = B - sum (ridx);

  % Calculate the bootstrap bias, standard error and confidence intervals 
  if (C > 0)

    %%%%%%%%%%%%%%%%%%%%%%%%%%% DOUBLE BOOTSTRAP %%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (ncpus > 1)
      % PARALLEL execution of inner layer resampling for double (i.e. iterated) bootstrap
      if (ISOCTAVE)
        % OCTAVE
        % Set unique random seed for each parallel thread
        pararrayfun (ncpus, @boot, 1, 1, false, 1:ncpus);
        if (vectorized && isempty (bootsam))
          cellfunc = @(x) bootknife (x, C, bootfun, NaN, strata, 0, [], T0, ISOCTAVE, false);
          bootout = parcellfun (ncpus, cellfunc, num2cell (X, 1), 'UniformOutput', false);
        else
          cellfunc = @(bootsam) bootknife (x(bootsam, :), C, bootfun, NaN, strata, 0, [], T0, ISOCTAVE, false);
          bootout = parcellfun (ncpus, cellfunc, num2cell (bootsam, 1), 'UniformOutput', false);
        end
      else
        % MATLAB
        % Set unique random seed for each parallel thread
        parfor i = 1:ncpus; boot (1, 1, false, i); end
        % Perform inner layer of resampling
        % Preallocate structure array
        bootout = cell (1, B);
        if (vectorized && isempty (bootsam))
          cellfunc = @(x) bootknife (x, C, bootfun, NaN, strata, 0, [], T0, ISOCTAVE, false);
          parfor b = 1:B; bootout{b} = cellfunc (X(:, b)); end
        else
          cellfunc = @(bootsam) bootknife (x(bootsam, :), C, bootfun, NaN, strata, 0, [], T0, ISOCTAVE, false);
          parfor b = 1:B; bootout{b} = cellfunc (bootsam(:, b)); end
        end
      end
    else
      % SERIAL execution of inner layer resampling for double bootstrap
      if (vectorized && isempty (bootsam))
        cellfunc = @(x) bootknife (x, C, bootfun, NaN, strata, 0, [], T0, ISOCTAVE, false);
        bootout = cellfun (cellfunc, num2cell (X, 1), 'UniformOutput', false);
      else
        cellfunc = @(bootsam) bootknife (x(bootsam, :), C, bootfun, NaN, strata, 0, [], T0, ISOCTAVE, false);
        bootout = cellfun (cellfunc, num2cell (bootsam, 1), 'UniformOutput', false);
      end
    end
    % Double bootstrap bias estimation
    mu = cell2mat (cellfun (@(S) S.bias, bootout, 'UniformOutput', false)) + ...
         cell2mat (cellfun (@(S) S.original, bootout, 'UniformOutput', false));
    b = mean (bootstat, 2) - T0;
    c = mean (mu, 2) - 2 * mean (bootstat, 2) + T0;
    bias = b - c;
    % Double bootstrap multiplicative correction of the standard error
    V = cell2mat (cellfun (@(S) S.std_error.^2, bootout, 'UniformOutput', false));
    se = sqrt (var (bootstat, 0, 2).^2 ./ mean (V, 2));
    % Double bootstrap confidence intervals
    if (~ isnan (alpha))
      U = cell2mat (cellfun (@(S) S.Pr, bootout, 'UniformOutput', false));
      l = zeros (m, 2);
      ci = zeros (m, 2);
      for j = 1:m
        % Calibrate interval coverage
        switch nalpha
          case 1
            % alpha is a two-tailed probability (scalar)
            % Calibrate central coverage and construct equal-tailed intervals (2-sided)
            [v, cdf] = localfunc.empcdf (abs (2 * U(j, :) - 1), true, 1);
            vk = interp1 (cdf, v, 1 - alpha, 'linear', max (v));
            l(j, :) = arrayfun (@(sign) 0.5 * (1 + sign * vk), [-1, 1]);
          case 2
            % alpha is a pair of probabilities (vector)
            % Calibrate coverage but construct endpoints separately (1-sided)
            % This is equivalent to algorithm 18.1 in Efron, and Tibshirani (1993)
            [u, cdf] = localfunc.empcdf (U(j, :), true, 1);
            l(j, 1) = interp1 (cdf, u, alpha(1), 'linear', min (u));
            l(j, 2) = interp1 (cdf, u, alpha(2), 'linear', max (u));
        end
        % Linear interpolation
        [t1, cdf] = localfunc.empcdf (bootstat(j, :), true, 1);
        ci(j, 1) = interp1 (cdf, t1, l(j, 1), 'linear', min (t1));
        ci(j, 2) = interp1 (cdf, t1, l(j, 2), 'linear', max (t1));
      end
    else
      ci = nan (m, 2);
    end

  else

    %%%%%%%%%%%%%%%%%%%%%%%%%%% SINGLE BOOTSTRAP %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bootstrap bias estimation
    bias = mean (bootstat, 2) - T0;
    % Bootstrap standard error
    se = std (bootstat, 0, 2);  % Unbiased since we used bootknife resampling
    if (~ isnan (alpha))
      % If bootfun is the arithmetic meam, expand the probability of the 
      % percentiles using Student's t-distribution
      if (strcmpi (bootfun_str, 'mean'))
        expan_alpha = (3 - nalpha) * localfunc.ExpandProbs (alpha / (3 - nalpha), n - K);
      else
        expan_alpha = alpha;
      end
      state = warning;
      if (ISOCTAVE)
        warning ('on', 'quiet');
      else
        warning ('off', 'all');
      end
      % Create distribution functions
      stdnormcdf = @(x) 0.5 * (1 + erf (x / sqrt (2)));
      stdnorminv = @(p) sqrt (2) * erfinv (2 * p - 1);
      switch nalpha
        case 1
          % Create equal-tailed probabilities for the percentiles
          l = repmat ([expan_alpha / 2, 1 - expan_alpha / 2], m, 1);
        case 2
          % Attempt to form bias-corrected and accelerated (BCa) bootstrap confidence intervals. 
          % Use the Jackknife to calculate the acceleration constant (a)
          try
            jackfun = @(i) bootfun (x(1:n ~= i, :));
            if (ncpus > 1)  
              % PARALLEL evaluation of bootfun on each jackknife resample 
              if (ISOCTAVE)
                % OCTAVE
                T = cell2mat (pararrayfun (ncpus, jackfun, 1:n, 'UniformOutput', false));
              else
                % MATLAB
                T = zeros (m, n);
                parfor i = 1:n; T(:, i) = feval (jackfun, i); end
              end
            else
              % SERIAL evaluation of bootfun on each jackknife resample
              T = cell2mat (arrayfun (jackfun, 1:n, 'UniformOutput', false));
            end
            % Calculate empirical influence function
            if (~ isempty (strata))
              gk = sum (g .* repmat (nk, n, 1), 2).';
              U = bsxfun (@times, gk - 1, bsxfun (@minus, mean (T, 2), T));  
            else
              U = (n - 1) * bsxfun (@minus, mean (T, 2), T);
            end
            a = sum (U.^3, 2) ./ (6 * sum (U.^2, 2) .^ 1.5);
          catch
            % Revert to bias-corrected (BC) bootstrap confidence intervals
            warning ('bootknife:jackfail', ...
              'BOOTFUN failed during jackknife calculations; acceleration constant set to 0\n');
            a = zeros (m, 1);
          end
          % Calculate the bias correction constant (z0)
          % Calculate the median bias correction z0
          z0 = stdnorminv (sum (bsxfun (@lt, bootstat, T0), 2) / B);
          if (~ all (isfinite (z0)))
            % Revert to percentile bootstrap confidence intervals
            warning ('bootknife:biasfail', ...
              'Unable to calculate the bias correction constant; reverting to percentile intervals\n');
            z0 = zeros (m, 1);
            a = zeros (m, 1); 
            l = repmat (expan_alpha, m, 1);
          end
          if (isempty (l))
            % Calculate BCa or BC percentiles
            z = stdnorminv (expan_alpha);
            l = cat (2, stdnormcdf (z0 + ((z0 + z(1)) ./ (1 - bsxfun (@times, a , z0 + z(1))))),... 
                        stdnormcdf (z0 + ((z0 + z(2)) ./ (1 - bsxfun (@times, a , z0 + z(2))))));
          end
      end
      % Intervals constructed from kernel density estimate of the bootstrap
      % (with shrinkage correction)
      ci = zeros (m, 2);
      for j = 1:m
        try
          ci(j, :) = localfunc.kdeinv (l(j, :), bootstat(j, :), se(j) * sqrt (1 / (n - K)), 1 - 1 / (n - K));
        catch
          % Linear interpolation (legacy)
          fprintf ('Note: Falling back to linear interpolation to calculate percentiles for interval pair %u\n', j);
          [t1, cdf] = localfunc.empcdf (bootstat(j, :), true, 1);
          ci(j, 1) = interp1 (cdf, t1, l(j, 1), 'linear', min (t1));
          ci(j, 2) = interp1 (cdf, t1, l(j, 2), 'linear', max (t1));
        end
      end
      warning (state);
      if (ISOCTAVE)
        warning ('off', 'quiet');
      end
    else
      ci = nan (m, 2);
    end

  end

  % Prepare output arguments
  stats = struct;
  stats.original = T0;
  stats.bias = bias;
  stats.std_error = se;
  stats.CI_lower = ci(:, 1);
  stats.CI_upper = ci(:, 2);
  % Use quick interpolation to find the proportion (Pr) of bootstat <= REF
  if ((nargin > 7) && ~ isempty (REF))
    I = bsxfun (@le, bootstat, REF);
    pr = sum (I, 2);
    t = cell2mat (arrayfun (@(j) ...
         [max([min(bootstat(j, :)), max(bootstat(j, I(j, :)))]),...
          min([max(bootstat(j, :)), min(bootstat(j, ~ I(j, :)))])], (1:m).', ...
          'UniformOutput', false));
    dt = t(:, 2) - t(:, 1);
    chk = and (pr < B, dt > 0);
    Pr = zeros (m, 1);
    Pr(chk, 1) = pr(chk, 1) + ((REF(chk, 1) - t(chk, 1) ).* ...
                        (min (pr(chk, 1) + 1, B) - pr(chk, 1)) ./ dt(chk, 1));
    Pr(~ chk, 1) = pr(~ chk, 1);
    stats.Pr = Pr / B;
  end
  bootstat = bootstat_all;

  % Print output if no output arguments are requested
  if (nargout == 0) 
    print_output (stats, nboot, alpha, l, m, bootfun_str, strata);
  else
    if (isempty (bootsam))
      [warnmsg, warnID] = lastwarn;
      if (ismember (warnID, {'bootknife:biasfail','bootknife:jackfail'}))
        warning ('bootknife:lastwarn', warnmsg);
      end
      lastwarn ('', '');
    end
  end

end

%--------------------------------------------------------------------------

function print_output (stats, nboot, alpha, l, m, bootfun_str, strata)

    fprintf (['\nSummary of nonparametric bootstrap estimates of bias and precision\n',...
              '******************************************************************************\n\n']);
    fprintf ('Bootstrap settings: \n');
    fprintf (' Function: %s\n', bootfun_str);
    if (nboot(2) > 0)
      if (isempty (strata))
        fprintf (' Resampling method: Iterated, balanced, bootknife resampling \n');
      else
        fprintf (' Resampling method: Iterated, stratified, balanced, bootknife resampling \n');
      end
    else
      if (isempty (strata))
        fprintf (' Resampling method: Balanced, bootknife resampling \n');
      else
        fprintf (' Resampling method: Stratified, balanced, bootknife resampling \n');
      end
    end
    fprintf (' Number of resamples (outer): %u \n', nboot(1));
    fprintf (' Number of resamples (inner): %u \n', nboot(2));
    if (~ isempty (alpha) && ~ all (isnan (alpha)))
      nalpha = numel (alpha);
      if (nboot(2) > 0)
        if (nalpha > 1)
          fprintf (' Confidence interval (CI) type: Calibrated percentile\n');
        else
          fprintf (' Confidence interval (CI) type: Calibrated percentile (equal-tailed)\n');
        end
      else
        if (nalpha > 1)
          [jnk, warnID] = lastwarn;
          switch warnID
            case 'bootknife:biasfail'
              if (strcmpi (bootfun_str, 'mean'))
                fprintf (' Confidence interval (CI) type: Expanded percentile\n');
              else
                fprintf (' Confidence interval (CI) type: Percentile\n');
              end
            case 'bootknife:jackfail'
              if (strcmpi (bootfun_str, 'mean'))
                fprintf (' Confidence interval (CI) type: Expanded bias-corrected (BC) \n');
              else
                fprintf (' Confidence interval (CI) type: Bias-corrected (BC) \n');
              end
            otherwise
              if (strcmpi (bootfun_str, 'mean'))
                fprintf (' Confidence interval (CI) type: Expanded bias-corrected and accelerated (BCa) \n');
              else
                fprintf (' Confidence interval (CI) type: Bias-corrected and accelerated (BCa) \n');
              end
          end
        else
          if (strcmpi (bootfun_str, 'mean'))
            fprintf (' Confidence interval (CI) type: Expanded percentile (equal-tailed)\n');
          else
            fprintf (' Confidence interval (CI) type: Percentile (equal-tailed)\n');
          end
        end
      end
      if (nalpha > 1)
        % alpha is a vector of probabilities
        coverage = 100 * abs (alpha(2) - alpha(1));
      else
        % alpha is a two-tailed probability
        coverage = 100 * (1 - alpha);
      end
      if (all (bsxfun (@eq, l, l(1, :))))
        fprintf (' Nominal coverage (and the percentiles used): %.3g%% (%.1f%%, %.1f%%)\n\n', coverage, 100 * l(1, :));
      else
        fprintf (' Nominal coverage: %.3g%%\n\n', coverage);
      end
    end
    fprintf ('Bootstrap Statistics: \n');
    fprintf (' original     bias         std_error    CI_lower     CI_upper  \n');
    for i = 1:m
      fprintf (' %#-+10.4g   %#-+10.4g   %#-+10.4g   %#-+10.4g   %#-+10.4g \n',... 
               [stats.original(i), stats.bias(i), stats.std_error(i), stats.CI_lower(i), stats.CI_upper(i)]);
    end
    fprintf ('\n');
    lastwarn ('', '');  % reset last warning

end

%--------------------------------------------------------------------------

function retval = col2args (func, x, szx)

  % Usage: retval = col2args (func, x, nvar)
  % col2args evaluates func on the columns of x. When nvar > 1, each of the
  % blocks of x are passed to func as a separate arguments. 

  % Extract columns of the matrix into a cell array
  [n, ncols] = size (x);
  xcell = mat2cell (x, n, ncols / sum (szx) * szx);

  % Evaluate column vectors as independent of arguments to bootfun
  retval = func (xcell{:});

end

%--------------------------------------------------------------------------

function [x, F, P] = empcdf (y, trim, m)

  % Subfunction to calculate empirical cumulative distribution function in the
  % presence of ties
  % https://brainder.org/2012/11/28/competition-ranking-and-empirical-distributions/

  % Check input argument
  if (~ isa (y, 'numeric'))
    error ('bootknife:empcdf: y must be numeric');
  end
  if (all (size (y) > 1))
    error ('bootknife:empcdf: y must be a vector');
  end
  if (size (y, 2) > 1)
    y = y.';
  end
  if (nargin < 2)
    trim = true;
  end
  if ( (~ islogical (trim)) && (~ ismember (trim, [0, 1])) )
    error ('bootknife:empcdf: m must be scalar');
  end
  if (nargin < 3)
    % Denominator in calculation of F is (N + m)
    % When m is 1, quantiles formed from x and F are akin to qtype (definition) 6
    % https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/quantile
    % Hyndman and Fan (1996) Am Stat. 50(4):361-365
    m = 0;
  end
  if (~ isscalar (m))
    error ('bootknife:empcdf: m must be scalar');
  end
  if (~ ismember (m, [0, 1]))
    error ('bootknife:empcdf: m must be either 0 or 1');
  end

  % Discard NaN values
  ridx = isnan (y);
  y(ridx) = [];

  % Get size of y
  N = numel (y);

  % Create empirical CDF accounting for ties by competition ranking
  x = sort (y);
  [jnk, IA, IC] = unique (x);
  N = numel (x);
  R = cat (1, IA(2:end) - 1, N);
  F = arrayfun (@(i) R(IC(i)), [1:N].') / (N + m);

  % Create p-value distribution accounting for ties by competition ranking
  P = 1 - arrayfun (@(i) IA(IC(i)) - 1, [1:N]') / N;

  % Remove redundancy
  if trim
    M = unique ([x, F, P], 'rows', 'last');
    x = M(:,1); F = M(:,2); P = M(:,3);
  end

end

%--------------------------------------------------------------------------

function X = kdeinv (P, Y, BW, CF)

  % Inverse of the cumulative density function (CDF) of a kernel density 
  % estimate (KDE)
  % 
  % The function returns X, the inverse CDF of the KDE of Y for the bandwidth
  % BW evaluated at the values in P. CF is a shrinkage factor for the variance
  % of the data in Y

  % Set defaults for optional input arguments
  if (nargin < 4)
    CF = 1;
  end

  % Create Normal CDF function
  pnorm = @(X, MU, SD) (0.5 * (1 + erf ((X - MU) / (SD * sqrt (2)))));

  % Calculate statistics of the data
  N = numel (Y);
  MU = mean (Y);

  % Apply shrinkage correction
  Y = ((Y - MU) * sqrt (CF)) + MU;

  % Set initial values of X0
  YS = sort (Y, 2);
  X0 = YS(fix ((N - 1) * P) + 1);

  % Perform root finding to get quantiles of the KDE at values of P
  findroot = @(X0, P) fzero (@(X) sum (pnorm (X - Y, 0, BW)) / N - P, X0);
  X = [-Inf, +Inf];
  for i = 1:numel(P)
    if (~ ismember (P(i), [0, 1]))
      X(i) = findroot (X0(i), P(i));
    end
  end

end

%--------------------------------------------------------------------------

function PX = ExpandProbs (P, DF)

  % Modify ALPHA to adjust tail probabilities assuming that the kurtosis of the
  % sampling distribution scales with degrees of freedom like the t-distribution.
  % This is related in concept to ExpandProbs in the resample R package:
  % https://www.rdocumentation.org/packages/resample/versions/0.6/topics/ExpandProbs

  % Get size of P
  sz = size (P);

  % Create required distribution functions
  stdnormcdf = @(X) 0.5 * (1 + erf (X / sqrt (2)));
  stdnorminv = @(P) sqrt (2) * erfinv (2 * P - 1);
  if (exist ('betaincinv', 'file'))
    studinv = @(P, DF) sign (P - 0.5) * ...
                       sqrt ( DF ./ betaincinv (2 * min (P, 1 - P), DF / 2, 0.5) - DF);
  else
    % Earlier versions of Matlab do not have betaincinv
    % Instead, use betainv from the Statistics and Machine Learning Toolbox
    try 
      studinv = @(P, DF) sign (P - 0.5) * ...
                         sqrt ( DF ./ betainv (2 * min (P, 1 - P), DF / 2, 0.5) - DF);
    catch
      % Use the Normal distribution (i.e. do not expand probabilities) if
      % either betaincinv or betainv are not available
      studinv = @(P, DF) stdnorminv (P);
      warning ('bootknife:ExpandProbs', ...
          'Could not create studinv function; intervals will not be expanded.');
    end
  end
 
  % Calculate statistics of the data
  PX = stdnormcdf (arrayfun (studinv, P, repmat (DF, sz)));

end

%--------------------------------------------------------------------------

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 95% expanded BCa bootstrap confidence intervals for the mean
%! bootknife (data, 2000, @mean);

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 95% calibrated percentile bootstrap confidence intervals for the mean
%! bootknife (data, [2000, 200], @mean);
%!
%! ## Please be patient, the calculations will be completed soon...

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 95% calibrated percentile bootstrap confidence intervals for the median
%! ## with smoothing.
%! bootknife (data, [2000, 200], @smoothmedian);
%!
%! ## Please be patient, the calculations will be completed soon...

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 90% equal-tailed percentile bootstrap confidence intervals for the variance
%! bootknife (data, 2000, {@var, 1}, 0.1);

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 90% BCa bootstrap confidence intervals for the variance
%! bootknife (data, 2000, {@var, 1}, [0.05 0.95]);

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 90% calibrated equal-tailed percentile bootstrap confidence intervals for
%! ## the variance.
%! bootknife (data, [2000, 200], {@var, 1}, 0.1);
%!
%! ## Please be patient, the calculations will be completed soon...

%!demo
%!
%! ## Input univariate dataset
%! data = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!         0 33 28 34 4 32 24 47 41 24 26 30 41].';
%!
%! ## 90% calibrated percentile bootstrap confidence intervals for the variance
%! bootknife (data, [2000, 200], {@var, 1}, [0.05, 0.95]);
%!
%! ## Please be patient, the calculations will be completed soon...

%!demo
%!
%! ## Input dataset
%! y = randn (20,1); x = randn (20,1); X = [ones(20,1), x];
%!
%! ## 90% BCa confidence interval for regression coefficients 
%! bootknife ({y,X}, 2000, @(y,X) X\y, [0.05 0.95]); % Could also use @regress


%!demo
%!
%! ## Input bivariate dataset
%! x = [576 635 558 578 666 580 555 661 651 605 653 575 545 572 594].';
%! y = [3.39 3.3 2.81 3.03 3.44 3.07 3 3.43 3.36 3.13 3.12 2.74 2.76 2.88 2.96].'; 
%!
%! ## 95% BCa bootstrap confidence intervals for the correlation coefficient
%! bootknife ({x, y}, 2000, @cor);
%!
%! ## Please be patient, the calculations will be completed soon...

%!demo
%!
%! ## Air conditioning failure times (x) in Table 1.2 of Davison A.C. and
%! ## Hinkley D.V (1997) Bootstrap Methods And Their Application. (Cambridge
%! ## University Press)
%!
%! ## AIM: to construct 95% nonparametric bootstrap confidence intervals for
%! ## the mean failure time from the sample x (n = 9). The mean(x,1) = 108.1 
%! ## and exact intervals based on an exponential model are [65.9, 209.2].
%!
%! ## Calculations using the 'bootstrap' and 'resample' packages in R
%! ##
%! ## x <- c(3, 5, 7, 18, 43, 85, 91, 98, 100, 130, 230, 487);
%! ##
%! ## library (bootstrap)  # Functions from Efron and Tibshirani (1993)
%! ## set.seed(1); ci1 <- boott (x, mean, nboott=20000, nbootsd=500, perc=c(.025,.975))
%! ## set.seed(1); ci2a <- bcanon (x, 20000, mean, alpha = c(0.025,0.975))
%! ##
%! ## library (resample)  # Functions from Hesterberg, Tim (2014)
%! ## bootout <- bootstrap (x, mean, R=20000, seed=1)
%! ## ci2b <- CI.bca (bootout, confidence=0.95, expand=FALSE)
%! ## ci3 <- CI.bca (bootout, confidence=0.95, expand=TRUE)
%! ## ci4 <- CI.percentile (bootout, confidence=0.95, expand=FALSE)
%! ## ci5 <- CI.percentile (bootout, confidence=0.95, expand=TRUE)
%! ##
%! ## Confidence intervals from 'bootstrap' and 'resample' packages in R
%! ##
%! ## method                                |   0.05 |   0.95 | length | shape |  
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## ci1a - bootstrap-t (bootstrap)        |   48.2 |  287.2 |  239.0 |  2.98 |
%! ## ci2a - BCa (bootstrap)                |   56.7 |  224.4 |  167.7 |  2.26 |
%! ## ci2b - BCa (resample)                 |   57.5 |  223.4 |  165.9 |  2.27 |
%! ## ci3  - expanded BCa (resample)        |   52.0 |  252.5 |  200.0 |  2.57 |
%! ## ci4  - percentile (resample)          |   47.7 |  191.8 |  144.1 |  1.39 |
%! ## ci5  - expanded percentile (resample) |   41.1 |  209.0 |  167.9 |  1.51 |
%!
%! ## Calculations using the 'statistics-bootstrap' package for Octave/Matlab
%! ##
%! ## x = [3 5 7 18 43 85 91 98 100 130 230 487]';
%! ## boot (1,1,false,1); ci3 = bootknife (x, 20000, @mean, [.025,.975]);
%! ## boot (1,1,false,1); ci5 = bootknife (x, 20000, @mean, 0.05);
%! ## boot (1,1,false,1); ci6 = bootknife (x, [20000,500], @mean, [.025,.975]);
%! ##
%! ## Confidence intervals from 'statistics-bootstrap' package for Octave/Matlab
%! ##
%! ## method                                |  0.025 |  0.975 | length | shape |
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## ci3  - expanded BCa                   |   50.6 |  253.0 |  202.4 |  2.52 |
%! ## ci5  - expanded percentile            |   36.9 |  207.2 |  170.3 |  1.39 |
%! ## ci6  - calibrated                     |   50.0 |  334.6 |  284.6 |  3.89 |
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## parametric - exact                    |   65.9 |  209.2 |  143.3 |  3.40 |
%! ##
%! ## Simulation results for constructing 95% confidence intervals for the
%! ## mean of populations with different distributions. The simulation was
%! ## of 1000 random samples of size 9 (analagous to the situation above). 
%! ## Simulation performed using the bootsim script with nboot of 2000.
%! ##
%! ## --------------------------------------------------------------------------
%! ## expanded BCa
%! ## --------------------------------------------------------------------------
%! ## Population                 | coverage |  lower |  upper | length | shape |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ## Normal N(0,1)              |    94.7% |   2.8% |   2.5% |   1.48 |  1.01 |
%! ## Folded normal |N(0,1)|     |    94.6% |   1.3% |   4.1% |   0.88 |  1.33 |
%! ## Exponential exp(1)         |    91.3% |   0.7% |   8.0% |   1.35 |  1.58 |
%! ## Log-normal exp(N(0,1))     |    88.4% |   0.4% |  11.2% |   2.21 |  1.81 |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ##
%! ## --------------------------------------------------------------------------
%! ## expanded percentile
%! ## --------------------------------------------------------------------------
%! ## Population                 | coverage |  lower |  upper | length | shape |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ## Normal N(0,1)              |    95.4% |   2.9% |   1.7% |   1.48 |  1.01 |
%! ## Folded normal |N(0,1)|     |    93.9% |   1.0% |   5.1% |   0.86 |  1.11 |
%! ## Exponential exp(1)         |    89.9% |   0.6% |   9.5% |   1.28 |  1.18 |
%! ## Log-normal exp(N(0,1))     |    85.6% |   0.0% |  14.4% |   2.05 |  1.25 |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ##
%! ## --------------------------------------------------------------------------
%! ## calibrated percentile (equal-tailed)
%! ## --------------------------------------------------------------------------
%! ## Population                 | coverage |  lower |  upper | length | shape |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ## Normal N(0,1)              |    95.7% |   2.4% |   1.9% |   1.76 |  1.06 |
%! ## Folded normal |N(0,1)|     |    96.3% |   1.5% |   2.2% |   1.03 |  1.78 |
%! ## Exponential exp(1)         |    93.9% |   0.8% |   5.3% |   1.50 |  2.06 |
%! ## Log-normal exp(N(0,1))     |    91.4% |   1.4% |   7.2% |   2.52 |  2.25 |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ##
%! ## --------------------------------------------------------------------------
%! ## calibrated percentile
%! ## --------------------------------------------------------------------------
%! ## Population                 | coverage |  lower |  upper | length | shape |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ## Normal N(0,1)              |    95.7% |   2.4% |   1.9% |   1.76 |  1.06 |
%! ## Folded normal |N(0,1)|     |    96.3% |   1.5% |   2.2% |   1.03 |  1.78 |
%! ## Exponential exp(1)         |    93.9% |   0.8% |   5.3% |   1.50 |  2.06 |
%! ## Log-normal exp(N(0,1))     |    91.4% |   1.4% |   7.2% |   2.52 |  2.25 |
%! ## ---------------------------|----------|--------|--------|--------|-------|

%!demo
%!
%! ## Spatial Test Data (A) from Table 14.1 of Efron and Tibshirani (1993)
%! ## An Introduction to the Bootstrap in Monographs on Statistics and Applied 
%! ## Probability 57 (Springer)
%!
%! ## AIM: to construct 90% nonparametric bootstrap confidence intervals for
%! ## var(A,1), where var(A,1) = 171.5 and n = 23, and exact intervals based
%! ## on Normal theory are [118.4, 305.2].
%! ##
%! ## (i.e. (n - 1) * var (A, 0) ./ chi2inv (1 - [0.05; 0.95], n - 1))
%!
%! ## Calculations using the 'boot' and 'bootstrap' packages in R
%! ## 
%! ## library (boot)       # Functions from Davison and Hinkley (1997)
%! ## A <- c(48,36,20,29,42,42,20,42,22,41,45,14,6,0,33,28,34,4,32,24,47,41,24,26,30,41);
%! ## n <- length(A)
%! ## var.fun <- function (d, i) { 
%! ##               # Function to compute the population variance
%! ##               n <- length (d); 
%! ##               return (var (d[i]) * (n - 1) / n) };
%! ## boot.fun <- function (d, i) {
%! ##               # Compute the estimate
%! ##               t <- var.fun (d, i);
%! ##               # Compute sampling variance of the estimate using Tukey's jackknife
%! ##               n <- length (d);
%! ##               U <- empinf (data=d[i], statistic=var.fun, type="jack", stype="i");
%! ##               var.t <- sum (U^2 / (n * (n - 1)));
%! ##               return ( c(t, var.t) ) };
%! ## set.seed(1)
%! ## var.boot <- boot (data=A, statistic=boot.fun, R=20000, sim='balanced')
%! ## ci1 <- boot.ci (var.boot, conf=0.90, type="norm")
%! ## ci2 <- boot.ci (var.boot, conf=0.90, type="perc")
%! ## ci3 <- boot.ci (var.boot, conf=0.90, type="basic")
%! ## ci4 <- boot.ci (var.boot, conf=0.90, type="bca")
%! ## ci5 <- boot.ci (var.boot, conf=0.90, type="stud")
%! ##
%! ## library (bootstrap)  # Functions from Efron and Tibshirani (1993)
%! ## set.seed(1); ci4a <- bcanon (A, 20000, var.fun, alpha=c(0.05,0.95))
%! ## set.seed(1); ci5a <- boott (A, var.fun, nboott=20000, nbootsd=500, perc=c(.05,.95))
%! ##
%! ## Confidence intervals from 'boot' and 'bootstrap' packages in R
%! ##
%! ## method                                |   0.05 |   0.95 | length | shape |  
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## ci1  - normal                         |  109.4 |  246.8 |  137.4 |  1.21 |
%! ## ci2  - percentile                     |   97.8 |  235.6 |  137.8 |  0.87 |
%! ## ci3  - basic                          |  107.4 |  245.3 |  137.9 |  1.15 |
%! ## ci4  - BCa                            |  116.9 |  264.0 |  147.1 |  1.69 |
%! ## ci4a - BCa                            |  116.2 |  264.0 |  147.8 |  1.67 |
%! ## ci5  - bootstrap-t                    |  111.8 |  291.2 |  179.4 |  2.01 |
%! ## ci5a - bootstrap-t                    |  112.7 |  292.6 |  179.9 |  2.06 |
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## parametric - exact                    |  118.4 |  305.2 |  186.8 |  2.52 |
%! ##
%! ## Summary of bias statistics from 'boot' package in R
%! ##
%! ## method                             | original |    bias | bias-corrected |
%! ## -----------------------------------|----------|---------|----------------|
%! ## single bootstrap                   |   171.53 |   -6.62 |         178.16 |
%! ## -----------------------------------|----------|---------|----------------|
%! ## parametric - exact                 |   171.53 |   -6.86 |         178.40 |
%!
%! ## Calculations using the 'statistics-bootstrap' package for Octave/Matlab
%! ##
%! ## A = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%! ##      0 33 28 34 4 32 24 47 41 24 26 30 41].';
%! ## boot (1,1,false,1); ci2 = bootknife (A, 20000, {@var,1}, 0.1);
%! ## boot (1,1,false,1); ci4 = bootknife (A, 20000, {@var,1}, [0.05,0.95]);
%! ## boot (1,1,false,1); ci6a = bootknife (A, [20000,500], {@var,1}, 0.1);
%! ## boot (1,1,false,1); ci6b = bootknife (A, [20000,500], {@var,1}, [0.05,0.95]);
%! ##
%! ## Confidence intervals from 'statistics-bootstrap' package for Octave/Matlab
%! ##
%! ## method                                |   0.05 |   0.95 | length | shape |
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## ci2  - percentile (equal-tailed)      |   96.6 |  236.7 |  140.1 |  0.87 |
%! ## ci4  - BCa                            |  115.7 |  266.1 |  150.4 |  1.69 |
%! ## ci6a - calibrated (equal-tailed)      |   82.3 |  256.4 |  174.1 |  0.95 |
%! ## ci6b - calibrated                     |  113.4 |  297.0 |  183.6 |  2.16 |
%! ## --------------------------------------|--------|--------|--------|-------|
%! ## parametric - exact                    |  118.4 |  305.2 |  186.8 |  2.52 |
%! ##
%! ## Simulation results for constructing 90% confidence intervals for the
%! ## variance of a population N(0,1) from 1000 random samples of size 26
%! ## (analagous to the situation above). Simulation performed using the
%! ## bootsim script with nboot of 2000 (for single bootstrap) or [2000,200]
%! ## (for double bootstrap).
%! ##
%! ## method                     | coverage |  lower |  upper | length | shape |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ## percentile (equal-tailed)  |    81.8% |   1.3% |  16.9% |   0.80 |  0.92 |
%! ## BCa                        |    87.3% |   4.2% |   8.5% |   0.86 |  1.85 |
%! ## calibrated (equal-tailed)  |    90.5% |   0.5% |   9.0% |   1.06 |  1.06 |
%! ## calibrated                 |    90.7% |   5.1% |   4.2% |   1.13 |  2.73 |
%! ## ---------------------------|----------|--------|--------|--------|-------|
%! ## parametric - exact         |    90.8% |   3.7% |   5.5% |   0.99 |  2.52 |
%!
%! ## Summary of bias statistics from 'boot' package in R
%! ##
%! ## method                             | original |    bias | bias-corrected |
%! ## -----------------------------------|----------|---------|----------------|
%! ## single bootstrap                   |   171.53 |   -6.70 |         178.24 |
%! ## double bootstrap                   |   171.53 |   -6.83 |         178.36 |
%! ## -----------------------------------|----------|---------|----------------|
%! ## parametric - exact                 |   171.53 |   -6.86 |         178.40 |
%!
%! ## The equivalent methods for constructing bootstrap intervals in the 'boot'
%! ## and 'bootstrap' packages (in R) and the statistics-bootstrap package (in
%! ## Octave/Matlab) produce intervals with very similar end points, length and
%! ## shape. However, all intervals calculated using the 'statistics-bootstrap'
%! ## package are slightly longer than the intervals calculated in R because
%! ## the 'statistics-bootstrap' package uses bootknife resampling. The scale of
%! ## the sampling distribution for small samples is approximated better by
%! ## bootknife (rather than bootstrap) resampling. 

%!test
%! ## Test for errors when using different functionalities of bootknife
%! ## 'bootknife:parallel' warning turned off in case parallel package is not loaded
%! warning ('off', 'bootknife:parallel')
%! try
%!   y = randn (20,1); 
%!   strata = [1;1;1;1;1;1;1;1;1;1;2;2;2;2;2;3;3;3;3;3];
%!   stats = bootknife (y, 2000, @mean);
%!   stats = bootknife (y, 2000, 'mean');
%!   stats = bootknife (y, 2000, {@var,1});
%!   stats = bootknife (y, 2000, {'var',1});
%!   stats = bootknife (y, 2000, @mean, [], strata);
%!   stats = bootknife (y, 2000, {'var',1}, [], strata);
%!   stats = bootknife (y, 2000, {@var,1}, [], strata, 2);
%!   stats = bootknife (y, 2000, @mean, .1, strata, 2);
%!   stats = bootknife (y, 2000, @mean, [.05,.95], strata, 2);
%!   stats = bootknife (y, [2000,200], @mean, .1, strata, 2);
%!   stats = bootknife (y, [2000,200], @mean, [.05,.95], strata, 2);
%!   stats = bootknife (y(1:5), 2000, @mean, .1);
%!   stats = bootknife (y(1:5), 2000, @mean, [.05,.95]);
%!   stats = bootknife (y(1:5), [2000,200], @mean, .1);
%!   stats = bootknife (y(1:5), [2000,200], @mean, [.05,.95]);
%!   Y = randn (20); 
%!   strata = [1;1;1;1;1;1;1;1;1;1;2;2;2;2;2;3;3;3;3;3];
%!   stats = bootknife (Y, 2000, @mean);
%!   stats = bootknife (Y, 2000, 'mean');
%!   stats = bootknife (Y, 2000, {@var, 1});
%!   stats = bootknife (Y, 2000, {'var',1});
%!   stats = bootknife (Y, 2000, @mean, [], strata);
%!   stats = bootknife (Y, 2000, {'var',1}, [], strata);
%!   stats = bootknife (Y, 2000, {@var,1}, [], strata, 2);
%!   stats = bootknife (Y, 2000, @mean, .1, strata, 2);
%!   stats = bootknife (Y, 2000, @mean, [.05,.95], strata, 2);
%!   stats = bootknife (Y, [2000,200], @mean, .1, strata, 2);
%!   stats = bootknife (Y, [2000,200], @mean, [.05,.95], strata, 2);
%!   stats = bootknife (Y(1:5,:), 2000, @mean, .1);
%!   stats = bootknife (Y(1:5,:), 2000, @mean, [.05,.95]);
%!   stats = bootknife (Y(1:5,:), [2000,200], @mean, .1);
%!   stats = bootknife (Y(1:5,:), [2000,200], @mean, [.05,.95]);
%!   stats = bootknife (Y, 2000, @(Y) mean(Y(:),1)); % Cluster/block resampling
%!   % Y(1,end) = NaN; % Unequal cluster size
%!   %stats = bootknife (Y, 2000, @(Y) mean(Y(:),1,'omitnan'));
%!   y = randn (20,1); x = randn (20,1); X = [ones(20,1), x];
%!   stats = bootknife ({x,y}, 2000, @cor);
%!   stats = bootknife ({x,y}, 2000, @cor, [], strata);
%!   stats = bootknife ({y,x}, 2000, @(y,x) pinv(x)*y); % Could also use @regress
%!   stats = bootknife ({y,X}, 2000, @(y,X) pinv(X)*y);
%!   stats = bootknife ({y,X}, 2000, @(y,X) pinv(X)*y, [], strata);
%!   stats = bootknife ({y,X}, 2000, @(y,X) pinv(X)*y, [], strata, 2);
%!   stats = bootknife ({y,X}, 2000, @(y,X) pinv(X)*y, [.05,.95], strata);
%! catch
%!   warning ('on', 'bootknife:parallel')
%!   rethrow (lasterror)
%! end
%! warning ('on', 'bootknife:parallel')

%!test
%! ## Air conditioning failure times in Table 1.2 of Davison A.C. and
%! ## Hinkley D.V (1997) Bootstrap Methods And Their Application. (Cambridge
%! ## University Press)
%! x = [3, 5, 7, 18, 43, 85, 91, 98, 100, 130, 230, 487]';
%!
%! ## Nonparametric 95% expanded percentile confidence intervals (equal-tailed )
%! ## Example 5.4 percentile intervals are 43.9 - 192.1
%! ## Note that the intervals calculated below are wider because the narrowness
%! ## bias was removed by expanding the probabilities of the percentiles using
%! ## Student's t-distribution
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife(x,2000,@mean,0.05);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 108.0833333333333, 1e-08);
%!   assert (stats.bias, -1.4210854715202e-14, 1e-08);
%!   assert (stats.std_error, 38.25414068983568, 1e-08);
%!   assert (stats.CI_lower, 37.62313309335625, 1e-08);
%!   assert (stats.CI_upper, 201.0264463378847, 1e-08);
%! end
%!
%! ## Nonparametric 95% expanded BCa confidence intervals
%! ## Example 5.8 BCa intervals are 55.33 - 243.5
%! ## Note that the intervals calculated below are wider because the narrowness
%! ## bias was removed by expanding the probabilities of the percentiles using
%! ## Student's t-distribution
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife(x,2000,@mean,[0.025,0.975]);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 108.0833333333333, 1e-08);
%!   assert (stats.bias, -1.4210854715202e-14, 1e-08);
%!   assert (stats.std_error, 38.25414068983568, 1e-08);
%!   assert (stats.CI_lower, 49.70873146256465, 1e-08);
%!   assert (stats.CI_upper, 232.3618260843778, 1e-08);
%! end
%!
%! ## Exact intervals based on an exponential model are 65.9 - 209.2
%! ## (Example 2.11)

%!test
%! ## Spatial test data from Table 14.1 of Efron and Tibshirani (1993)
%! ## An Introduction to the Bootstrap in Monographs on Statistics and Applied 
%! ## Probability 57 (Springer)
%! A = [48 36 20 29 42 42 20 42 22 41 45 14 6 ...
%!      0 33 28 34 4 32 24 47 41 24 26 30 41]';
%!
%! ## Nonparametric 90% equal-tailed percentile confidence intervals
%! ## Table 14.2 percentile intervals are 100.8 - 233.9
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife(A,2000,{@var,1},0.1);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 171.534023668639, 1e-08);
%!   assert (stats.bias, -7.323387573964482, 1e-08);
%!   assert (stats.std_error, 43.30079972388541, 1e-08);
%!   assert (stats.CI_lower, 95.24158837039771, 1e-08);
%!   assert (stats.CI_upper, 237.7156378257705, 1e-08);
%! end
%!
%! ## Nonparametric 90% BCa confidence intervals
%! ## Table 14.2 BCa intervals are 115.8 - 259.6
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife(A,2000,{@var,1},[0.05 0.95]);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 171.534023668639, 1e-08);
%!   assert (stats.bias, -7.323387573964482, 1e-08);
%!   assert (stats.std_error, 43.30079972388541, 1e-08);
%!   assert (stats.CI_lower, 113.2388308884533, 1e-08);
%!   assert (stats.CI_upper, 264.9901439787903, 1e-08);
%! end
%!
%! ## Nonparametric 90% calibrated equal-tailed percentile confidence intervals
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife(A,[2000,200],{@var,1},0.1);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 171.534023668639, 1e-08);
%!   assert (stats.bias, -8.088193809171344, 1e-08);
%!   assert (stats.std_error, 46.53418481731099, 1e-08);
%!   assert (stats.CI_lower, 79.46067430166357, 1e-08);
%!   assert (stats.CI_upper, 260.9171292390822, 1e-08);
%! end
%!
%! ## Nonparametric 90% calibrated percentile confidence intervals
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife(A,[2000,200],{@var,1},[0.05,0.95]);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 171.534023668639, 1e-08);
%!   assert (stats.bias, -8.088193809171344, 1e-08);
%!   assert (stats.std_error, 46.53418481731099, 1e-08);
%!   assert (stats.CI_lower, 110.6138073406352, 1e-08);
%!   assert (stats.CI_upper, 305.1908284023669, 1e-08);
%! end
%!
%! ## Exact intervals based on normal theory are 118.4 - 305.2 (Table 14.2)
%! ## Note that all of the bootknife intervals are slightly wider than the
%! ## nonparametric intervals in Table 14.2 because the bootknife (rather than
%! ## standard bootstrap) resampling used here reduces small sample bias

%!test
%! ## Law school data from Table 3.1 of Efron and Tibshirani (1993)
%! ## An Introduction to the Bootstrap in Monographs on Statistics and Applied 
%! ## Probability 57 (Springer)
%! LSAT = [576 635 558 578 666 580 555 661 651 605 653 575 545 572 594]';
%! GPA = [3.39 3.3 2.81 3.03 3.44 3.07 3 3.43 3.36 3.13 3.12 2.74 2.76 2.88 2.96]';
%!
%! ## Nonparametric 90% equal-tailed percentile confidence intervals
%! ## Percentile intervals on page 266 are 0.524 - 0.928
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife({LSAT,GPA},2000,@cor,0.1);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 0.7763744912894071, 1e-08);
%!   assert (stats.bias, -0.008259337758776963, 1e-08);
%!   assert (stats.std_error, 0.1420949476115542, 1e-08);
%!   assert (stats.CI_lower, 0.5056363801008388, 1e-08);
%!   assert (stats.CI_upper, 0.9586254199016858, 1e-08);
%! end
%!
%! ## Nonparametric 90% BCa confidence intervals
%! ## BCa intervals on page 266 are 0.410 - 0.923
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife({LSAT,GPA},2000,@cor,[0.05 0.95]);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 0.7763744912894071, 1e-08);
%!   assert (stats.bias, -0.008259337758776963, 1e-08);
%!   assert (stats.std_error, 0.1420949476115542, 1e-08);
%!   assert (stats.CI_lower, 0.4119228032301614, 1e-08);
%!   assert (stats.CI_upper, 0.9300646701004258, 1e-08);
%! end
%!
%! ## Nonparametric 90% calibrated equal-tailed percentile confidence intervals
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife({LSAT,GPA},[2000,500],@cor,0.1);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 0.7763744912894071, 1e-08);
%!   assert (stats.bias, -0.00942010836534779, 1e-08);
%!   assert (stats.std_error, 0.1438249935781226, 1e-08);
%!   assert (stats.CI_lower, 0.3706033532632082, 1e-08);
%!   assert (stats.CI_upper, 0.978329929008979, 1e-08);
%! end
%!
%! ## Nonparametric 90% calibrated percentile confidence intervals
%! boot (1, 1, false, 1); # Set random seed
%! stats = bootknife({LSAT,GPA},[2000,500],@cor,[0.05,0.95]);
%! if (isempty (regexp (which ('boot'), 'mex$')))
%!   ## test boot m-file result
%!   assert (stats.original, 0.7763744912894071, 1e-08);
%!   assert (stats.bias, -0.00942010836534779, 1e-08);
%!   assert (stats.std_error, 0.1438249935781226, 1e-08);
%!   assert (stats.CI_lower, 0.2307337185192847, 1e-08);
%!   assert (stats.CI_upper, 0.9444347128107354, 1e-08);
%! end
%! ## Exact intervals based on normal theory are 0.51 - 0.91