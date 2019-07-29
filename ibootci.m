%  Function File: ibootci
%
%  Bootstrap confidence interval
%
%  ci = ibootci(nboot,bootfun,...)
%  ci = ibootci(nboot,{bootfun,...},...,'alpha',alpha)
%  ci = ibootci(nboot,{bootfun,...},...,'type',type)
%  ci = ibootci(nboot,{bootfun,...},...,'Weights',weights)
%  ci = ibootci(nboot,{bootfun,...},...,'bootidx',bootidx)
%  [ci,bootstat] = ibootci(...)
%  [ci,bootstat,S] = ibootci(...)
%  [ci,bootstat,S,calcurve] = ibootci(...)
%  [ci,bootstat,S,calcurve,bootidx] = ibootci(...)
%
%  ci = ibootci(nboot,bootfun,...) computes the 95% iterated (double)
%  bootstrap confidence interval of the statistic computed by bootfun.
%  nboot is a scalar, or vector of upto two positive integers indicating
%  the number of replicate samples for the first and second bootstraps.
%  bootfun is a function handle specified with @, or a string indicating
%  the function name. The third and later input arguments are data (column
%  vectors), that are used to create inputs to bootfun. ibootci creates
%  each first level bootstrap by sampling from the rows of the column
%  vector data arguments (which must be the same size) [1]. Nominal central
%  coverage of two-sided intervals is calibrated to achieve second order
%  accurate coverage by bootstrap iteration and interpolation [2]. Linear
%  interpolation of the empirical cumulative distribution function of
%  bootstat is then used to construct two-sided confidence intervals [3].
%  The resampling method used throughout is balanced resampling [4].
%  Default values for the number of first and second bootstrap replicate
%  sample sets in nboot are 5000 and 200 respectively.
%
%  ci = ibootci(nboot,{bootfun,...},...,'alpha',alpha) computes the
%  iterated bootstrap confidence interval of the statistic defined by the
%  function bootfun with coverage 100*(1-alpha)%, where alpha is a scalar
%  value between 0 and 1. bootfun and the data that ibootci passes to it
%  are contained in a single cell array. The default value of alpha is
%  0.05 corresponding to intervals with a coverage of 95% confidence.
%
%  ci = ibootci(nboot,{bootfun,...},...,'type',type) computes the bootstrap
%  confidence interval of the statistic defined by the function bootfun.
%  type is the confidence interval type, chosen from among the following:
%    'per' or 'percentile' - Percentile method. (Default)
%    'bca' - Bias corrected and accelerated percentile method.
%
%  ci = ibootci(nboot,{bootfun,...},...,'Weights',weights) specifies
%  observation weights. weights must be a vector of non-negative numbers.
%  The dimensions of weights must be equal to that of the non-scalar input
%  arguments to bootfun. The weights are used as bootstrap sampling
%  probabilities. Note that weights are not implemented for bootstrap
%  iteration. To improve on standard percentile intervals from a single
%  bootstrap when using weights, we suggest calibrating the nominal
%  alpha level using iterated bootstrap without weights, then using
%  the calibrated alpha in a weighted bootstrap without iteration
%  (see example 4 below).
%
%  ci = ibootci(nboot,{bootfun,...},...,'bootidx',bootidx) performs
%  bootstrap computations using the indices from bootidx for the first
%  bootstrap.
%
%  [ci,bootstat] = ibootci(...) also returns the bootstrapped statistic
%  computed for each of the nboot first bootstrap replicate samples.
%  Each row of bootstat contains the results of applying bootfun to
%  one replicate sample from the first bootstrap.
%
%  [ci,bootstat,S] = ibootci(...) also returns a structure containing
%  the settings used in the bootstrap and the resulting statistics.
%
%  [ci,bootstat,S,calcurve] = ibootci(...) also returns the calibration
%  curve for central coverage. The first column is nominal coverage and
%  the second column is actual coverage.
%
%  [ci,bootstat,S,calcurve,bootidx] = ibootci(...) also returns bootidx,
%  a matrix of indices from the first bootstrap.
%
%  Bibliography:
%  [1] Efron, B. and Tibshirani, R.J. (1993) An Introduction to the
%       Bootstrap. New York, NY: Chapman & Hall
%  [2] Hall, Lee and Young (2000) Importance of interpolation when
%       constructing double-bootstrap confidence intervals. Journal
%       of the Royal Statistical Society. Series B. 62(3): 479-491
%  [3] Efron, B. (1981) Censored data and the bootstrap. JASA
%       76(374): 312-319
%  [4] Davison et al. (1986) Efficient Bootstrap Simulation.
%       Biometrika, 73: 555–66
%
%  Example 1: Two alternatives for 95% confidence intervals for the mean
%    >> y = randn(20,1);
%    >> ci = ibootci([5000 200],@mean,y);
%    >> ci = ibootci([5000 200],{@mean,y},'alpha',0.05);
%
%  Example 2: 95% confidence intervals for the means of paired/matched data
%    >> y1 = randn(20,1);
%    >> y2 = randn(20,1);
%    >> [ci1,bootstat,S,calcurve,bootidx] = ibootci([5000 200],{@mean,y1});
%    >> [ci2] = ibootci(5000,{@mean,y2},'bootidx',bootidx,'alpha',S.cal);
%
%  Example 3: 95% confidence intervals for the correlation coefficient
%    >> z = mvnrnd([2,3],[1,1.5;1.5,3],20);
%    >> x = z(:,1); y = z(:,2);
%    >> func = @(x,y) sum((x-mean(x)).*(y-mean(y)))./...
%    >>        (sqrt(sum((x-mean(x)).^2)).*sqrt(sum((y-mean(y)).^2)));
%    >> ci = ibootci([5000 200],{func,x,y});
%  Note that this is much faster than:
%    >> ci = ibootci([5000 200],{@corr,x,y});
%
%  Example 4: 95% confidence interval for the weighted arithmetic mean
%    >> y = randn(20,1);
%    >> w = [ones(5,1)*10/(20*5);ones(15,1)*10/(20*15)];
%    >> [ci,~,S] = ibootci([5000,200],{'mean',y},'alpha',0.05);
%    >> ci = ibootci(5000,{'mean',y},'alpha',S.cal,'Weights',w);
%
%  Example 5: 95% confidence interval for the median by smoothed bootstrap
%  (requires the smoothmedian function available at Matlab Central File Exchange)
%    >> y = randn(20,1);
%    >> ci = ibootci([5000 200],@smoothmedian,y);
%
%  Example 6: 95% confidence interval for the 25% trimmed (or interquartile) mean
%    >> y = randn(20,1);
%    >> func = @(x) trimmean(x,50)
%    >> ci = ibootci([5000 200],func,y);
%
%  The syntax in this function code is known to be compatible with
%  recent versions of Octave (v3.2.4 on Debian 6 Linux 2.6.32) and
%  Matlab (v7.4.0 on Windows XP).
%
%  ibootci v1.8.5.0 (26/07/2019)
%  Author: Andrew Charles Penn
%  https://www.researchgate.net/profile/Andrew_Penn/


function [ci,bootstat,S,calcurve,idx] = ibootci(argin1,argin2,varargin)

  % Evaluate the number of function arguments
  if nargin<2 || (nargin<3 && ~iscell(argin2))
    error('Too few input arguments');
  end
  if nargout>5
   error('Too many output arguments');
  end

  % Assign input arguments to function variables
  if ~iscell(argin2)
    nboot = argin1;
    bootfun = argin2;
    data = varargin;
    alpha = 0.05;
    idx = [];
    weights = [];
    type = 'per';
  else
    nboot = argin1;
    bootfun = argin2{1};
    data = {argin2{2:end}};
    options = varargin;
    alpha = 1+find(strcmpi('alpha',options));
    type = 1+find(strcmpi('type',options));
    weights = 1+find(strcmpi('Weights',options));
    bootidx = 1+find(strcmpi('bootidx',options));
    if ~isempty(alpha)
      try
        alpha = options{alpha};
      catch
        alpha = 0.05;
      end
    else
      alpha = 0.05;
    end
    if ~isempty(type)
      try
        type = options{type};
      catch
        type = 'per';
      end
    else
      type = 'per';
    end
    if ~isempty(weights)
      try
        weights = options{weights};
      catch
        weights = [];
      end
    else
      weights = [];
    end
    if ~isempty(bootidx)
      try
        idx = options{bootidx};
      catch
        error('Could not find bootidx')
      end
      if size(data{1},1) ~= size(idx,1)
        error('Dimensions of data and bootidx are inconsistent')
      end
      % Set nboot(1) according to the size of bootidx
      nboot(1) = size(idx,2);
    else
      idx = [];
    end
  end
  if ischar(bootfun)
    % Convert character string of a function name to a function handle
    bootfun = str2func(bootfun);
  end
  iter = numel(nboot);
  nvar = size(data,2);

  % Evaluate function variables
  if iter > 2
    error('Size of nboot exceeds maximum number of iterations supported by ibootci')
  end
  if ~isa(nboot,'numeric')
    error('nboot must be numeric');
  end
  if any(nboot~=abs(fix(nboot)))
    error('nboot must contain positive integers')
  end
  if ~isa(alpha,'numeric') || numel(alpha)~=1
    error('The alpha value must be a numeric scalar value');
  end
  if (alpha <= 0) || (alpha >= 1)
    error('The alpha value must be a value between 0 and 1');
  end
  if ~any(strcmpi(type,{'per','percentile'})) && ~strcmpi(type,'bca')
    error('The type of bootstrap must be either per or bca');
  end
  varclass = zeros(1,nvar);
  rows = zeros(1,nvar);
  cols = zeros(1,nvar);
  for v = 1:nvar
    varclass(v) = isa(data{v},'double');
    if all(size(data{v})>1)
      error('The data must be provided as vectors')
    end
    rows(v) = size(data{v},1);
    cols(v) = size(data{v},2);
  end
  if ~all(varclass)
    error('Data variables must be double precision')
  end
  if any(rows~=rows(1)) || any(cols~=cols(1))
    error('The dimensions of the data are not consistent');
  end
  rows = rows(1);
  cols = cols(1);
  if max(rows,cols) == 1
    error('Cannot bootstrap scalar values');
  elseif cols>1
    % Transpose row vector data
    n = cols;
    for v = 1:nvar
      data{v} = data{v}';
    end
  else
    n = rows;
  end
  if isempty(weights)
    weights = ones(n,1);
  else
    if ~all(size(weights) == [rows,cols])
      error('The weights vector is not the same dimensions as the data');
    end
    if cols>1
      % Transpose row vector weights
      weights = weights';
    end
  end
  if any(weights<0)
    error('weights must be a vector of non-negative numbers')
  end

  % Evaluate bootfun
  if ~isa(bootfun,'function_handle')
    error('bootfun must be a function name or function handle');
  end
  try
    T0 = feval(bootfun,data{:});
  catch
    error('An error occurred while trying to evaluate bootfun with the input data');
  end
  if isinf(T0) | isnan(T0)
    error('bootfun returns a NaN or Inf')
  end
  if max(size(T0))>1
    error('Column vector inputs to bootfun must return a scalar');
  end
  M = cell(1,nvar);
  for v = 1:nvar
    x = data{v};
    % Minimal simulation to evaluate bootfun with matrix input arguments
    if v == 1
      simidx = randi(n,n,2);
    end
    M{v} = x(simidx);
  end
  try
    sim = feval(bootfun,M{:});
    if size(sim,1)>1
      error('Invoke catch statement');
    end
    runmode = 'fast';
  catch
    warning('ibootci:slowMode',...
            'Slow mode. Faster if matrix input arguments to bootfun return a row vector.')
    runmode = 'slow';
  end

  % Set the bootstrap sample sizes
  S = struct;
  if iter==0
    B = 5000;
    C = 200;
    nboot = [B C];
  elseif iter==1
    B = nboot;
    C = 0;
    nboot = [B C];
  elseif iter==2
    B = nboot(1);
    C = nboot(2);
  end
  if C>0
    if (1/min(alpha,1-alpha)) > (0.5 * C)
      error('ibootci:extremeAlpha',...
           ['The calibrated alpha is too extreme for calibration so the result will be unreliable. \n',...
            'Try increasing the number of replicate samples in the second bootstrap.\n',...
            'If the problem persists, the original sample size may be inadequate.\n']);
    end
    if any(diff(weights))
      error('Weights are not implemented for iterated bootstrap.');
    end
  end
  S.bootfun = bootfun;
  S.nboot = nboot;
  S.type = type;

  % Convert alpha to coverage level (decimal format)
  S.alpha = alpha;
  S.coverage = 1-alpha;
  alpha = 1-alpha;

  % Perform bootstrap
  % Bootstrap resampling
  if isempty(idx)
    if nargout < 4
      [T1, U] = boot1 (data, nboot, n, nvar, bootfun, T0, weights, runmode);
    else
      [T1, U, idx] = boot1 (data, nboot, n, nvar, bootfun, T0, weights, runmode);
    end
  else
    X1 = cell(1,nvar);
    for v = 1:nvar
      X1{v} = data{v}(idx);
    end
    switch lower(runmode)
      case {'fast'}
        T1 = feval(bootfun,X1{:})';
      case {'slow'}
        T1 = zeros(1,nboot(1));
        for i=1:nboot(1)
          x1 = cellfun(@(X1)X1(:,i),X1,'UniformOutput',false);
          T1(i) = feval(bootfun,x1{:});
        end
    end
    % Perform second bootstrap if applicable
    if C>0
      U = zeros(1,B);
      for h = 1:B
        U(h) = boot2 (X1, nboot, n, nvar, bootfun, T0, runmode);
      end
      U = U/C;
    end
  end

  % Calculate statistics for the first bootstrap sample set
  bootstat = T1.';
  bias = mean(bootstat)-T0;

  % Calibrate central two-sided coverage
  if C>0
    % Create a calibration curve
    V = abs(2*U-1);
    [calcurve(:,2),calcurve(:,1)] = empcdf(V,1);
    alpha = interp1(calcurve(:,2),calcurve(:,1),alpha,'linear','extrap');
  else
    calcurve = [];
  end
  S.cal = 1-alpha;

  % Check the nominal central coverage
  if (S.cal == 0)
    warning('ibootci:calibrationHitEnd',...
            ['The calibration of alpha has hit the ends of the bootstrap distribution \n',...
             'and may be unreliable. Try increasing the number of replicate samples for the second \n',...
             'bootstrap. If the problem persists, the original sample size may be inadequate.\n']);
  end

  % Construct confidence interval (with calibrated central coverage)
  switch lower(type)
    case {'per','percentile'}
      % Percentile
      m1 = 0.5*(1+alpha);
      m2 = 0.5*(1-alpha);
      S.z0 = 0;
      S.a = 0;
    case 'bca'
      % Bias correction and acceleration (BCa)
      [m1, m2, S] = BCa(B, bootfun, data, T1, T0, alpha, weights, S);
  end

  % Linear interpolation of the bootstat cdf for interval construction
  [cdf,t1] = empcdf(T1,1);
  UL = interp1(cdf,t1,m1,'linear','extrap');
  LL = interp1(cdf,t1,m2,'linear','extrap');
  ci = [LL;UL];

  % Check the confidence interval limits
  if (m2 < cdf(2)) || (m1 > cdf(end-1))
    warning('ibootci:intervalHitEnd',...
            ['The confidence interval has hit the end(s) of the bootstrap distribution \n',...
             'and may be unreliable. Try increasing the number of replicate samples in the second \n',...
             'bootstrap. If the problem persists, the original sample size may be inadequate.\n']);
  end

  % Complete output structure
  S.stat = T0;                     % Sample test statistic
  if any(diff(weights))
    S.bias = NaN;                  % Bias not available for weighted bootstrap
    S.bc_stat = NaN;               % Bias correction not available for weighted bootstrap
  else
    S.bias = bias;                 % Bias of the test statistic
    S.bc_stat = T0-bias;           % Bias-corrected test statistic
  end
  S.SE = std(bootstat,0);          % Bootstrap standard error of the test statistic
  S.ci = ci;                       % Bootstrap confidence intervals of the test statistic
  if min(weights) ~= max(weights)
    S.weights = weights;
  else
    S.weights = [];
  end

end

%--------------------------------------------------------------------------

function [T1, U, idx] = boot1 (x, nboot, n, nvar, bootfun, T0, weights, runmode)

    % Initialize
    B = nboot(1);
    C = nboot(2);
    N = n*B;
    T1 = zeros(1,B);
    U = zeros(1,B);
    X1 = cell(1,nvar);
    if nargout < 3
      idx = zeros(n,1);
    else
      idx = zeros(n,B);
    end

    % Prepare weights for resampling
    if any(diff(weights))
      c = cumsum(round(N * weights./sum(weights)));
      c(end) = N;
      c = [c(1);diff(c)];
    else
      c = ones(n,1)*B;
    end

    % Since first bootstrap is large, use a memory
    % efficient balanced resampling algorithm
    for h = 1:B
      for i = 1:n
        j = sum((rand(1) >= cumsum(c./sum(c))))+1;
        if nargout < 3
          idx(i,1) = j;
        else
          idx(i,h) = j;
        end
        c(j) = c(j)-1;
      end
      for v = 1:nvar
        if nargout < 3
          X1{v} = x{v}(idx);
        else
          X1{v} = x{v}(idx(:,h));
        end
      end
      T1(h) = feval(bootfun,X1{:});
      % Since second bootstrap is usually much smaller, perform rapid
      % balanced resampling by a permutation algorithm
      if C>0
        U(h) = boot2 (X1, nboot, n, nvar, bootfun, T0, runmode);
      end
    end
    U = U/C;

end

%--------------------------------------------------------------------------

function [U] = boot2 (X1, nboot, n, nvar, bootfun, T0, runmode)

    % Note that weights are not implemented here with iterated bootstrap

    % Initialize
    C = nboot(2);
    N = n*C;

    % Rapid balanced resampling by permutation
    idx = (1:n)'*ones(1,C);
    idx = idx(reshape(randperm(N,N),n,C));
    X2 = cell(1,nvar);
    for v = 1:nvar
      X2{v} = X1{v}(idx);
    end
    switch lower(runmode)
      case {'fast'}
        % Vectorized calculation of second bootstrap statistics
        T2 = feval(bootfun,X2{:});
      case {'slow'}
        % Calculation of second bootstrap statistics using a loop
        T2 = zeros(1,C);
        for i=1:C
          x2 = cellfun(@(X2)X2(:,i),X2,'UniformOutput',false);
          T2(i) = feval(bootfun,x2{:});
        end
    end
    U = sum(T2<=T0);
    if U < 1
      U = 0;
    elseif U == C
      U = C;
    else
      % Quick linear interpolation to approximate asymptotic calibration
      t2 = zeros(1,2);
      I = (T2<=T0);
      if any(I)
        t2(1) = max(T2(I));
      else
        t2(1) = min(T2);
      end
      I = (T2>T0);
      if any(I)
        t2(2) = min(T2(I));
      else
        t2(2) = max(T2);
      end
      if (t2(2)-t2(1) == 0)
        U = t2(1);
      else
        U = ((t2(2)-T0)*U + (T0-t2(1))*(U+1)) /...
                (t2(2) - t2(1));
      end
    end

end

%--------------------------------------------------------------------------

function [SE, T, U] = jack (x, func)

  % Ordinary Jackknife

  if nargin < 2
    error('Invalid number of input arguments');
  end

  if nargout > 3
    error('Invalid number of output arguments');
  end

  % Perform 'leave one out' procedure and calculate the variance(s)
  % of the test statistic.
  nvar = size(x,2);
  m = size(x{1},1);
  ridx = diag(ones(m,1));
  j = (1:m)';
  M = cell(1,nvar);
  for v = 1:nvar
    M{v} = x{v}(j(:,ones(m,1)),:);
    M{v}(ridx==1,:)=[];
  end
  T = zeros(m,1);
  for i = 1:m
    Mi = cell(1,nvar);
    for v = 1:nvar
      Mi{v} = M{v}(1:m-1);
      M{v}(1:m-1)=[];
    end
    T(i,:) = feval(func,Mi{:});
  end
  Tori = mean(T,1);
  Tori = Tori(ones(m,1),:);
  U = ((m-1)*(Tori-T));
  Var = (m-1)/m*sum((T-Tori).^2,1);

  % Calculate standard error(s) of the functional parameter
  SE = sqrt(Var);

end

%--------------------------------------------------------------------------

function [m1, m2, S] = BCa (B, func, x, T1, T0, alpha, weights, S)

  % Note that alpha input argument is nominal coverage

  % Prepare weights
  m = size(x{1},1);
  if any(diff(weights))
    weights = weights./sum(weights);
  else
    weights = ones(m,1)/m;
  end

  % Calculate bias correction z0
  z0 = norminv(sum(T1<T0)/B);

  % Calculate acceleration constant a
  try
    % Get Jackknife statistics
    [SE, T] = jack(x,func);
    % Calculate acceleration (including weights)
    Tori = sum(weights.*T);
    U = ((m-1)*(Tori-T));
    a = (1/6)*(sum(weights.*U.^3)/sum(weights.*U.^2)^(3/2)/sqrt(m));
  catch
    a = nan;
  end

  % Check if calculation of acceleration using the jackknife was successful
  if isnan(a)
    % If not, directly calculate from the skewness of the bootstrap statistics
    a = (1/6)*skewness(T1,1);
  end

  % Calculate confidence limits
  z1 = norminv(0.5*(1+alpha));
  m1 = normcdf(z0+((z0+z1)/(1-a*(z0+z1))));
  z2 = norminv(0.5*(1-alpha));
  m2 = normcdf(z0+((z0+z2)/(1-a*(z0+z2))));
  S.z0 = z0;
  S.a = a;

end

%--------------------------------------------------------------------------

function [F,x] = empcdf (y,c)

  % Calculate empirical cumulative distribution function of y
  %
  % Set c to:
  %  1 to have a complete distribution with F ranging from 0 to 1
  %  0 to avoid duplicate values in x
  %
  % Unlike ecdf, empcdf uses a denominator of N+1

  % Check input argument
  if ~isa(y,'numeric')
    error('y must be numeric')
  end
  if all(size(y)>1)
    error('y must be a vector')
  end
  if size(y,2)>1
    y = y.';
  end

  % Create empirical CDF
  x = sort(y);
  N = sum(~isnan(y));
  [x,F] = unique(x,'rows','last');
  F = F/(N+1);

  % Apply option to complete the CDF
  if c > 0
    x = [x(1);x;x(end)];
    F = [0;F;1];
  end

end
