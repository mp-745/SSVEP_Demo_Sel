%% LCA Visualisation -- Leaky Competing Accumulator Race
%  Based on Usher & McClelland (2001), Eq. 4, p. 559
%
%  Simulates and plots the accumulator race for an SSVEP-BCI scenario
%  with 2 or 3 frequency targets across six different scenarios.
%
%  Includes a Bayesian boundary optimizer that tunes the decision threshold
%  by running Monte Carlo simulations across a grid of boundary values,
%  fitting a Gaussian process surrogate, and picking the boundary that
%  maximises a speed-accuracy utility function.
%
%  Just hit Run (or F5). Requires the Statistics and Machine Learning
%  Toolbox (for fitrgp and slicesample).

close all; clear; clc;

%% ==================== LCA PARAMETERS ====================

params.k        = 0.15;    % net leak (lambda - alpha)
params.beta     = 0.10;    % lateral inhibition
params.sigma    = 0.08;    % noise SD (increased: real EEG is noisy)
params.tau      = 1.0;     % time scale (seconds)
params.dt       = 0.01;    % integration step (small for smooth plots)
params.boundary = 3.0;     % decision threshold

%% ==================== SCENARIOS ====================

scenarios = struct();

% 1. Clear 15 Hz signal (Daisy looking at 15 Hz)
scenarios(1).rho    = [0.70, 0.20, 0.10];
scenarios(1).labels = {'15 Hz', '20 Hz', 'x Hz'};
scenarios(1).params = params;
scenarios(1).tMax   = 2.0;
scenarios(1).title  = 'Clear signal: Daisy looking at 15 Hz';

% 2. Ambiguous (no clear gaze target)
scenarios(2).rho    = [0.35, 0.33, 0.32];
scenarios(2).labels = {'15 Hz', '20 Hz', 'x Hz'};
scenarios(2).params = params;
scenarios(2).tMax   = 2.0;
scenarios(2).title  = 'Ambiguous: no clear gaze target';

% 3. Two-way competition (15 Hz vs 20 Hz, x Hz weak)
scenarios(3).rho    = [0.50, 0.45, 0.05];
scenarios(3).labels = {'15 Hz', '20 Hz', 'x Hz'};
scenarios(3).params = params;
scenarios(3).tMax   = 3.0;
scenarios(3).title  = '15 Hz vs 20 Hz competition';

% 4. High inhibition (beta = 0.25)
paramsHighInhib = params;
paramsHighInhib.beta = 0.25;
scenarios(4).rho    = [0.50, 0.45, 0.05];
scenarios(4).labels = {'15 Hz', '20 Hz', 'x Hz'};
scenarios(4).params = paramsHighInhib;
scenarios(4).tMax   = 3.0;
scenarios(4).title  = 'High inhibition (\beta = 0.25)';

% 5. High leak (k = 0.40)
paramsHighLeak = params;
paramsHighLeak.k = 0.40;
scenarios(5).rho    = [0.70, 0.20, 0.10];
scenarios(5).labels = {'15 Hz', '20 Hz', 'x Hz'};
scenarios(5).params = paramsHighLeak;
scenarios(5).tMax   = 3.0;
scenarios(5).title  = 'High leak (k = 0.40)';

% 6. Two-class only (original 15 vs 20 Hz)
scenarios(6).rho    = [0.65, 0.35];
scenarios(6).labels = {'15 Hz', '20 Hz'};
scenarios(6).params = params;
scenarios(6).tMax   = 2.0;
scenarios(6).title  = 'Two-class: 15 Hz vs 20 Hz only';

%% ==================== RUN SCENARIOS (once, reuse for both plots) ===========

rng(42);

colours = [0.169 0.341 0.592;   % blue   (#2B5797)
           0.906 0.298 0.235;   % red    (#E74C3C)
           0.153 0.682 0.376;   % green  (#27AE60)
           0.953 0.612 0.071;   % yellow (#F39C12)
           0.557 0.267 0.678];  % purple (#8E44AD)

nScenarios = numel(scenarios);

% Pre-run all scenarios and cache results
scResults = struct('tVec', cell(1, nScenarios), 'xMat', cell(1, nScenarios), ...
                   'winner', cell(1, nScenarios), 'crossTime', cell(1, nScenarios));
for si = 1:nScenarios
    sc = scenarios(si);
    [scResults(si).tVec, scResults(si).xMat, ...
     scResults(si).winner, scResults(si).crossTime] = runLCA(sc.rho, sc.params, sc.tMax);
end

%% ==================== PANEL PLOT (all 6 scenarios in one figure) ===========

figure('Name', 'LCA Scenario Comparison', 'NumberTitle', 'off', ...
       'Position', [50, 50, 1100, 750]);

for si = 1:nScenarios
    sc = scenarios(si);
    tVec = scResults(si).tVec;  xMat = scResults(si).xMat;
    winner = scResults(si).winner;  crossTime = scResults(si).crossTime;

    subplot(3, 2, si);
    hold on;

    nAccum = numel(sc.rho);
    for ai = 1:nAccum
        plot(tVec, xMat(:, ai), 'Color', colours(ai, :), 'LineWidth', 1.5);
    end

    yline(sc.params.boundary, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);

    if winner > 0
        plot(crossTime, sc.params.boundary, 'kd', ...
             'MarkerSize', 8, 'MarkerFaceColor', colours(winner, :));
    end

    xlabel('Time (s)');
    ylabel('Activation');
    title(sc.title, 'FontSize', 10);
    legend(sc.labels, 'Location', 'northwest', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Leaky Competing Accumulator: Scenario Comparison', ...
        'FontSize', 14, 'FontWeight', 'bold');

fprintf('Done. Scenario comparison panel created.\n');

%% ====================================================================
%%              BAYESIAN BOUNDARY OPTIMISATION
%% ====================================================================
%  The idea: sweep a range of boundary values, run many Monte Carlo LCA
%  trials at each boundary, measure accuracy and latency, compute a
%  utility score, then fit a Gaussian process to find the optimum.
%
%  This is a simplified standalone version of bayesianBoundaryOptimizer.m
%  for visualisation purposes. The full pipeline version uses real EEG
%  replay; here we simulate from known rho distributions.
%
%  The utility function balances the speed-accuracy tradeoff:
%    U(b) = w_acc * accuracy - w_lat * latency - w_err * error_rate
%
%  Wider boundary  -> slower, more accurate  (conservative)
%  Narrower boundary -> faster, less accurate (liberal)
%  The Bayesian optimizer finds the sweet spot for your data.

fprintf('\n=== BAYESIAN BOUNDARY OPTIMISATION ===\n');

% --- Optimiser config ---
optCfg.boundaryGrid = linspace(0.5, 6.0, 30);  % candidate boundaries
optCfg.nTrials      = 20000;                    % MC trials per boundary
optCfg.tMax         = 3.0;                      % max time per trial
optCfg.wAccuracy    = 1.0;                      % utility weight: accuracy
optCfg.wLatency     = 0.4;                      % utility weight: latency penalty
optCfg.wError       = 2.0;                      % utility weight: wrong commands (high cost for BCI)
optCfg.wHold        = 0.2;                      % utility weight: HOLD rate penalty

% --- Simulate a realistic mixture of "conditions" ---
%  In real use, these come from replaying EEG through classifiers.
%  Here we sample rho from distributions that mimic real SSVEP evidence
%  with REALISTIC overlap. Real CCA correlations are noisier and closer
%  together than idealised simulations suggest, especially:
%    - The target frequency only has moderate advantage over distractors
%    - Non-target frequencies still produce non-trivial correlations
%    - Trial-to-trial variability is high (SD ~0.12)
%    - Rest trials still generate weak, noisy evidence across all accumulators
%
%  Three accumulators: 15 Hz, 20 Hz, x Hz (third SSVEP frequency)
%  Four conditions: look at 15 Hz, look at 20 Hz, look at x Hz, rest
%
%  True label: 1 = 15 Hz, 2 = 20 Hz, 3 = x Hz, 0 = rest (should be HOLD)

conditionProbs = [0.30, 0.30, 0.20, 0.20];  % P(15), P(20), P(x), P(rest)
nAccum = 3;
freqLabels = {'15 Hz', '20 Hz', 'x Hz'};

% Rho distribution parameters per condition [mean_target, mean_distractor, SD_target, SD_distractor]
%  Target rho is only moderately above distractors (realistic for 8ch EEG)
%  Distractors are not zero -- they pick up harmonics, alpha bleed, etc.
rhoTarget    = 0.45;   % mean CCA correlation for the attended frequency
rhoDistract  = 0.28;   % mean for non-attended frequencies (not that far below)
rhoRest      = 0.25;   % mean during rest (weak noise-driven correlations)
sdTarget     = 0.12;   % high trial-to-trial variability
sdDistract   = 0.10;
sdRest       = 0.08;

rng(42);

% --- Prior over boundary: log-normal ---
%  Encodes the belief that boundary is probably around 2-4 before seeing data
priorMu    = log(3.0);   % log-space mean (boundary ~3.0)
priorSigma = 0.4;        % log-space SD (covers roughly 1.5 to 6.0)
% Full log-normal log-pdf: -log(b) - 0.5*((log(b)-mu)/sigma)^2
% The -log(b) Jacobian term is needed for a proper log-normal density.
priorLogPdf = @(b) -log(b) - 0.5 * ((log(b) - priorMu) / priorSigma).^2;

% --- Run Monte Carlo at each boundary ---
nGrid   = numel(optCfg.boundaryGrid);
accVec  = zeros(nGrid, 1);
latVec  = zeros(nGrid, 1);
errVec  = zeros(nGrid, 1);
holdVec = zeros(nGrid, 1);
utilVec = zeros(nGrid, 1);

% SDT (Signal Detection Theory) counters per boundary
sdtHits    = zeros(nGrid, 1);  % signal trial, correct class detected
sdtMisses  = zeros(nGrid, 1);  % signal trial, HOLD (no decision)
sdtConfuse = zeros(nGrid, 1);  % signal trial, wrong class detected
sdtFA      = zeros(nGrid, 1);  % noise trial (rest), any detection
sdtCR      = zeros(nGrid, 1);  % noise trial (rest), correct HOLD

fprintf('Running %d boundaries x %d trials = %d simulations...\n', ...
        nGrid, optCfg.nTrials, nGrid * optCfg.nTrials);

% Extract config into plain variables for parfor compatibility
nTrials    = optCfg.nTrials;
tMaxOpt    = optCfg.tMax;
wAccuracy  = optCfg.wAccuracy;
wLatency   = optCfg.wLatency;
wError     = optCfg.wError;
wHold      = optCfg.wHold;
bGridVec   = optCfg.boundaryGrid;
condProbs  = conditionProbs;
cumCondP   = cumsum(condProbs);
pSignal    = condProbs(1) + condProbs(2) + condProbs(3);  % all target conditions
pRest      = condProbs(4);                                % rest condition

% Pre-generate condition assignments and rho noise for all trials/boundaries.
% This moves the random sampling outside the inner loop to reduce overhead,
% and makes the rho construction branchless (lookup table instead of if/else).
%
% Condition lookup: rows = [15Hz, 20Hz, xHz, rest], cols = accumulators
%   Mean rho per [condition x accumulator]:
rhoMeans = [rhoTarget,   rhoDistract, rhoDistract;   % cond 1: look at 15 Hz
            rhoDistract, rhoTarget,   rhoDistract;   % cond 2: look at 20 Hz
            rhoDistract, rhoDistract, rhoTarget;     % cond 3: look at x Hz
            rhoRest,     rhoRest,     rhoRest];      % cond 4: rest
rhoSDs   = [sdTarget,   sdDistract, sdDistract;
            sdDistract, sdTarget,   sdDistract;
            sdDistract, sdDistract, sdTarget;
            sdRest,     sdRest,     sdRest];

% Map trueClass: conditions 1-3 are signal, condition 4 maps to class 0 (rest)
classMap = [1, 2, 3, 0];

parfor gi = 1:nGrid
    pTrial = params;
    pTrial.boundary = bGridVec(gi);

    nCorrect  = 0;
    nError    = 0;
    nHold     = 0;
    nDecided  = 0;
    totalLat  = 0;

    % SDT counters for this boundary
    hits = 0; misses = 0; confusions = 0; fa = 0; cr = 0;

    % Pre-generate random numbers for this boundary's trials
    condRand  = rand(nTrials, 1);         % for condition sampling
    rhoNoise  = randn(nTrials, nAccum);   % for rho perturbation

    for ti = 1:nTrials
        % Determine condition via cumulative probability lookup
        r = condRand(ti);
        if r < cumCondP(1),     cond = 1;
        elseif r < cumCondP(2), cond = 2;
        elseif r < cumCondP(3), cond = 3;
        else,                   cond = 4;
        end
        trueClass = classMap(cond);

        % Build rho from lookup table (no branching per accumulator)
        rho = max(rhoMeans(cond, :) + rhoSDs(cond, :) .* rhoNoise(ti, :), 0);

        [winner, crossTime] = runLCA_fast(rho, pTrial, tMaxOpt);

        if winner == 0
            nHold = nHold + 1;
            if trueClass == 0
                cr = cr + 1;
            else
                misses = misses + 1;
            end
        elseif trueClass == 0
            nError   = nError + 1;
            nDecided = nDecided + 1;
            totalLat = totalLat + crossTime;
            fa = fa + 1;
        elseif winner == trueClass
            nCorrect  = nCorrect + 1;
            nDecided  = nDecided + 1;
            totalLat  = totalLat + crossTime;
            hits = hits + 1;
        else
            nError     = nError + 1;
            nDecided   = nDecided + 1;
            totalLat   = totalLat + crossTime;
            confusions = confusions + 1;
        end
    end

    accVec(gi)  = nCorrect / nTrials;
    errVec(gi)  = nError   / nTrials;
    holdVec(gi) = nHold    / nTrials;

    sdtHits(gi)    = hits;
    sdtMisses(gi)  = misses;
    sdtConfuse(gi) = confusions;
    sdtFA(gi)      = fa;
    sdtCR(gi)      = cr;

    if nDecided > 0
        latVec(gi) = totalLat / nDecided;
    else
        latVec(gi) = tMaxOpt;
    end

    % Utility: accuracy - latency penalty - error cost - HOLD penalty
    nSignal      = nTrials * pSignal;
    holdOnSignal = max(nHold - nTrials * pRest, 0) / nSignal;

    utilVec(gi) = wAccuracy * accVec(gi) ...
                - wLatency  * (latVec(gi) / tMaxOpt) ...
                - wError    * errVec(gi) ...
                - wHold     * holdOnSignal;
end

fprintf('Done.\n');

%% ==================== SIGNAL DETECTION THEORY (SDT) ====================
%  Compute d' (sensitivity) and c (criterion) at each boundary.
%
%    Signal trial = target present (trueClass = 1, 2, or 3)
%    Noise trial  = rest (trueClass = 0)
%    Hit          = signal trial, correct class detected
%    Miss         = signal trial, HOLD (no decision -- safe)
%    Confusion    = signal trial, wrong class detected (dangerous)
%    False alarm  = noise trial, any detection fired
%    Correct rej  = noise trial, HOLD
%
%  d' uses only hitRate vs faRate. Confusions reduce hitRate (they are NOT
%  counted as hits), so d' implicitly penalises confusions without needing
%  a separate term.
%
%  d' = z(hitRate) - z(faRate)
%  c  = -0.5 * [z(hitRate) + z(faRate)]    (positive c = conservative)

% Expected counts from condition probabilities
% (actual counts vary per boundary due to random sampling, but with 20k
% trials the difference is negligible -- using expected counts keeps the
% denominators consistent across boundaries)
nSigExp   = round(nTrials * pSignal);
nNoiseExp = nTrials - nSigExp;

% Rates -- each computed from its own denominator
%   hitRate    = correct detections / signal trials
%   missRate   = HOLD on signal / signal trials  (safe error: drone stays put)
%   confuseRate = wrong class on signal / signal trials  (dangerous: wrong command)
%   faRate     = any detection on rest / noise trials    (dangerous: unprompted command)
%
% By construction: hitRate + missRate + confuseRate = 1.0 on signal trials
%                  faRate  + crRate                 = 1.0 on noise trials
%
% Log-linear correction (Hautus 1995) applied to hitRate and faRate only,
% since these feed into the z-transform for d'. Miss and confusion rates
% are not z-transformed so no correction needed.
hitRate     = (sdtHits   + 0.5) ./ (nSigExp   + 1);
faRate      = (sdtFA     + 0.5) ./ (nNoiseExp + 1);
missRate    = sdtMisses  ./ max(nSigExp,   1);   % HOLD-only misses
confuseRate = sdtConfuse ./ max(nSigExp,   1);   % wrong-class errors

% z-transform (inverse normal CDF) for d' and criterion
zHit = norminv(hitRate);
zFA  = norminv(faRate);

% d' measures sensitivity: ability to detect signal AND identify correct class
% vs firing on rest. Confusions reduce the hit rate, so d' correctly penalises
% both miss types (HOLD and wrong class) without double-counting.
dPrime    = zHit - zFA;
criterion = -0.5 * (zHit + zFA);

% Print SDT summary at best raw MC boundary (MCMC posterior summary printed later)
[~, rawBestIdx] = max(utilVec);
fprintf('\n=== SIGNAL DETECTION THEORY ===\n');
fprintf('At best MC boundary (%.2f):\n', bGridVec(rawBestIdx));
fprintf('  Signal trials (%d expected):\n', nSigExp);
fprintf('    Hit rate:       %.1f%%  (correct class detected)\n', hitRate(rawBestIdx)*100);
fprintf('    Miss rate:      %.1f%%  (HOLD -- safe, drone stays put)\n', missRate(rawBestIdx)*100);
fprintf('    Confusion rate: %.1f%%  (wrong class -- dangerous)\n', confuseRate(rawBestIdx)*100);
% Sum check uses raw counts (not Hautus-corrected hitRate) so it sums to 100%
fprintf('    Check (sum=1):  %.1f%%\n', ...
        (sdtHits(rawBestIdx) + sdtMisses(rawBestIdx) + sdtConfuse(rawBestIdx)) / nSigExp * 100);
fprintf('  Noise trials (%d expected):\n', nNoiseExp);
fprintf('    FA rate:        %.1f%%  (%d detections -- dangerous)\n', ...
        faRate(rawBestIdx)*100, sdtFA(rawBestIdx));
fprintf('  d'' = %.2f\n', dPrime(rawBestIdx));
fprintf('  c  = %.2f  (%s)\n', criterion(rawBestIdx), ...
        sdtCriterionLabel(criterion(rawBestIdx)));
fprintf('\nInterpretation:\n');
if dPrime(rawBestIdx) > 2.0
    fprintf('  d'' > 2.0: strong discriminability. The LCA can reliably tell signal from noise.\n');
elseif dPrime(rawBestIdx) > 1.0
    fprintf('  d'' = %.2f: moderate discriminability. Some signal/noise overlap.\n', dPrime(rawBestIdx));
else
    fprintf('  d'' = %.2f: weak discriminability. Signal and noise distributions overlap heavily.\n', dPrime(rawBestIdx));
end
if confuseRate(rawBestIdx) > 0.10
    fprintf('  Confusion rate > 10%%: the LCA often picks the wrong class.\n');
    fprintf('  This suggests the two SSVEP evidence streams are not well separated.\n');
end

% --- Fit Gaussian Process surrogate (Statistics and Machine Learning Toolbox) ---
%  fitrgp learns the kernel hyperparameters from data (instead of us
%  hand-tuning length scale etc.), giving a much better surrogate.

bGrid  = optCfg.boundaryGrid(:);
bDense = linspace(0.3, 7.0, 200)';
fprintf('\nFitting GP surrogate (fitrgp)...\n');
gpModel = fitrgp(bGrid, utilVec, ...
    'KernelFunction', 'squaredexponential', ...
    'Standardize', true, ...
    'Sigma', 0.01, ...                     % low noise: 20k MC trials per point
    'ConstantSigma', true);

% Predict on dense grid
[gpMean, gpStd] = predict(gpModel, bDense);

% GP predictive function for any scalar boundary
gpPredMean = @(b) predict(gpModel, b(:));

% --- Log-posterior = scaled GP utility + log-prior ---
%  Scale GP so its peak-to-trough spans ~10 log-units. This makes the
%  data strongly informative relative to the prior.
logPrior  = priorLogPdf(bDense);
gpRange   = max(gpMean) - min(gpMean);
if gpRange < 1e-6, gpRange = 1; end
gpScale   = 10.0 / gpRange;

logPosterior = gpScale * gpMean + logPrior;

% MAP estimate (for comparison with MCMC)
[~, mapIdx]   = max(logPosterior);
mapBoundary   = bDense(mapIdx);

% Find where the raw MC utility peaks
[~, rawIdx]   = max(utilVec);
rawBestBound  = optCfg.boundaryGrid(rawIdx);

% ======================================================================
%  MCMC: Slice sampling from the posterior over boundary
% ======================================================================
%  Slice sampling (Neal, 2003) auto-tunes the step size, so there's no
%  proposal SD to fiddle with and no acceptance rate to worry about.
%  Uses the Statistics and Machine Learning Toolbox's slicesample().
%
%  The target is the unnormalised log-posterior:
%    log p(b | data) propto gpScale * GP_mean(b) + log_prior(b)

fprintf('\n--- Running MCMC (slice sampling) ---\n');

mcmcCfg.nSamples = 12000;
mcmcCfg.burnIn   = 2000;

% Log-posterior function for the sampler
%  IMPORTANT: boundary must be positive. Return -Inf for b <= 0 so the
%  sampler never explores non-physical negative thresholds.
%  Also clamp to the GP training range to avoid extrapolation artefacts.
bLo = min(bGrid) * 0.5;   % allow slight extrapolation below grid
bHi = max(bGrid) * 1.2;   % allow slight extrapolation above grid
logPostFn = @(b) logPosteriorFn(b, gpModel, gpScale, priorLogPdf, bLo, bHi);

% Slice sampler (auto-tunes step size)
rng(42);
mcmcChain = slicesample(mapBoundary, mcmcCfg.nSamples, ...
    'logpdf', logPostFn, ...
    'burnin', mcmcCfg.burnIn, ...
    'thin', 2, ...           % keep every 2nd sample to reduce autocorrelation
    'width', 1.5);           % initial step size hint

fprintf('Effective samples: %d (after burn-in + thinning)\n', numel(mcmcChain));

nPosterior = numel(mcmcChain);

% Posterior summary statistics
posteriorMean   = mean(mcmcChain);
posteriorMedian = median(mcmcChain);
posteriorStd    = std(mcmcChain);
ci95            = quantile(mcmcChain, [0.025, 0.975]);
ci80            = quantile(mcmcChain, [0.10, 0.90]);

% Use posterior mean as the Bayes-optimal boundary
optBoundary = posteriorMean;
optUtility  = gpPredMean(optBoundary);

% --- Diagnostics: theoretical asymptote ---
rhoTypical   = 0.65;
xSteadyState = rhoTypical / params.k;
fprintf('\n--- Dynamics check ---\n');
fprintf('Steady-state for rho=%.2f, k=%.2f:  x_ss = %.2f\n', ...
        rhoTypical, params.k, xSteadyState);
fprintf('Default boundary = %.2f  -->  %s\n', params.boundary, ...
        iff(xSteadyState > params.boundary, 'REACHABLE (but slow)', 'UNREACHABLE'));

fprintf('\n--- MCMC Results ---\n');
fprintf('Posterior mean boundary:     %.2f\n', posteriorMean);
fprintf('Posterior median boundary:   %.2f\n', posteriorMedian);
fprintf('Posterior SD:                %.2f\n', posteriorStd);
fprintf('95%% credible interval:       [%.2f, %.2f]\n', ci95(1), ci95(2));
fprintf('80%% credible interval:       [%.2f, %.2f]\n', ci80(1), ci80(2));
fprintf('MAP boundary (comparison):   %.2f\n', mapBoundary);
fprintf('Raw MC best boundary:        %.2f\n', rawBestBound);
fprintf('Prior mean boundary:         %.2f\n', exp(priorMu));
optAcc = interp1(bGrid, accVec, optBoundary, 'pchip');
optLat = interp1(bGrid, latVec, optBoundary, 'pchip');
fprintf('Utility at posterior mean:   %.3f\n', optUtility);
fprintf('Accuracy at posterior mean:  ~%.1f%%\n', optAcc * 100);
fprintf('Mean latency at post. mean:  ~%.2fs\n', optLat);
fprintf('x_ss / boundary = %.2f  (>1 = reachable)\n', ...
        xSteadyState / optBoundary);

% SDT at posterior mean (interpolate from grid, skip NaN entries)
validSDT = ~isnan(dPrime) & ~isnan(criterion);
optDPrime = interp1(bGrid(validSDT), dPrime(validSDT), optBoundary, 'pchip');
optC      = interp1(bGrid(validSDT), criterion(validSDT), optBoundary, 'pchip');
optHR     = interp1(bGrid, hitRate,     optBoundary, 'pchip');
optMR     = interp1(bGrid, missRate,    optBoundary, 'pchip');
optFAR    = interp1(bGrid, faRate,      optBoundary, 'pchip');
optConfR  = interp1(bGrid, confuseRate, optBoundary, 'pchip');

fprintf('\n--- SDT at posterior mean ---\n');
fprintf('  d'' = %.2f,  c = %.2f (%s)\n', optDPrime, optC, sdtCriterionLabel(optC));
fprintf('  Signal trials:  Hit %.1f%%  |  Miss (HOLD) %.1f%%  |  Confusion %.1f%%\n', ...
        optHR*100, optMR*100, optConfR*100);
fprintf('  Noise trials:   FA %.1f%%\n', optFAR*100);

%% ==================== PLOT: BAYESIAN BOUNDARY TUNING ====================

% ---- Figure A: MC simulation results + GP surrogate (4 panels) ----

figure('Name', 'MC Simulation Results', 'NumberTitle', 'off', ...
       'Position', [80, 80, 1000, 650]);

% --- Subplot 1: Accuracy vs Boundary ---
subplot(2, 2, 1);
hold on;
plot(bGrid, accVec * 100, 'o-', 'Color', colours(1,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(1,:));
% Shade 95% CI region
fill([ci95(1), ci95(2), ci95(2), ci95(1)], ...
     [0, 0, 100, 100], [0.8 0.2 0.2], 'FaceAlpha', 0.08, 'EdgeColor', 'none');
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
xlabel('Boundary'); ylabel('Accuracy (%)');
title('Accuracy vs Boundary');
grid on; box on; hold off;

% --- Subplot 2: Latency vs Boundary ---
subplot(2, 2, 2);
hold on;
plot(bGrid, latVec, 'o-', 'Color', colours(2,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(2,:));
fill([ci95(1), ci95(2), ci95(2), ci95(1)], ...
     [0, 0, max(latVec)*1.1, max(latVec)*1.1], [0.8 0.2 0.2], ...
     'FaceAlpha', 0.08, 'EdgeColor', 'none');
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
xlabel('Boundary'); ylabel('Mean latency (s)');
title('Latency vs Boundary');
grid on; box on; hold off;

% --- Subplot 3: Error rate + HOLD rate ---
subplot(2, 2, 3);
hold on;
plot(bGrid, errVec * 100, 'o-', 'Color', colours(2,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(2,:));
plot(bGrid, holdVec * 100, 's-', 'Color', colours(3,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(3,:));
fill([ci95(1), ci95(2), ci95(2), ci95(1)], ...
     [0, 0, 100, 100], [0.8 0.2 0.2], 'FaceAlpha', 0.08, 'EdgeColor', 'none');
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
xlabel('Boundary'); ylabel('Rate (%)');
title('Error rate and HOLD rate');
legend({'Errors', 'HOLDs'}, 'Location', 'east');
grid on; box on; hold off;

% --- Subplot 4: GP surrogate + prior ---
subplot(2, 2, 4);
hold on;
fill([bDense; flipud(bDense)], ...
     [gpMean + gpStd; flipud(gpMean - gpStd)], ...
     colours(1,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(bDense, gpMean, '-', 'Color', colours(1,:), 'LineWidth', 2);
plot(bGrid, utilVec, 'k.', 'MarkerSize', 10);
priorCurve = exp(priorLogPdf(bDense));
priorScaled = priorCurve / max(priorCurve) * (max(gpMean) - min(gpMean)) * 0.5 + min(gpMean);
plot(bDense, priorScaled, ':', 'Color', [0.6 0.4 0.1], 'LineWidth', 1.5);
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
xline(mapBoundary, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.0);
xlabel('Boundary'); ylabel('Utility');
title('GP surrogate + log-normal prior');
legend({'GP +/- 1 SD', 'GP mean', 'MC observed', 'Prior (scaled)', ...
        'MCMC mean', 'MAP'}, 'Location', 'southwest', 'FontSize', 7);
grid on; box on; hold off;

sgtitle('Monte Carlo Simulation Results', 'FontSize', 14, 'FontWeight', 'bold');

% ---- Figure B: SDT Analysis (4 panels) ----

figure('Name', 'Signal Detection Theory', 'NumberTitle', 'off', ...
       'Position', [90, 70, 1000, 650]);

% --- Subplot 1: d' vs boundary ---
subplot(2, 2, 1);
hold on;
plot(bGrid, dPrime, 'o-', 'Color', colours(1,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(1,:));
yline(0, ':', 'Color', [0.5 0.5 0.5]);
yline(1.0, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8);
text(bGrid(end)*0.85, 1.1, 'd'' = 1.0', 'FontSize', 8, 'Color', [0.5 0.5 0.5]);
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
xlabel('Boundary'); ylabel('d'' (sensitivity)');
title('Sensitivity (d'')');
grid on; box on; hold off;

% --- Subplot 2: Criterion vs boundary ---
subplot(2, 2, 2);
hold on;
plot(bGrid, criterion, 'o-', 'Color', colours(5,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(5,:));
yline(0, ':', 'Color', [0.5 0.5 0.5]);
fill([bGrid(1), bGrid(end), bGrid(end), bGrid(1)], ...
     [0, 0, max(criterion)*1.2, max(criterion)*1.2], ...
     [0.9 0.95 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
fill([bGrid(1), bGrid(end), bGrid(end), bGrid(1)], ...
     [min(criterion)*1.2, min(criterion)*1.2, 0, 0], ...
     [1.0 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
% Re-plot line on top
plot(bGrid, criterion, 'o-', 'Color', colours(5,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(5,:));
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
text(bGrid(end)*0.6, max(criterion)*0.8, 'conservative', ...
     'FontSize', 9, 'Color', [0.3 0.3 0.8]);
text(bGrid(end)*0.6, min(criterion)*0.8, 'liberal', ...
     'FontSize', 9, 'Color', [0.8 0.3 0.3]);
xlabel('Boundary'); ylabel('c (criterion)');
title('Response bias (criterion c)');
grid on; box on; hold off;

% --- Subplot 3: Hit rate, FA rate, confusion rate ---
subplot(2, 2, 3);
hold on;
plot(bGrid, hitRate*100, 'o-', 'Color', colours(3,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(3,:));
plot(bGrid, faRate*100, 's-', 'Color', colours(2,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(2,:));
plot(bGrid, confuseRate*100, 'd-', 'Color', colours(4,:), 'LineWidth', 1.5, ...
     'MarkerSize', 4, 'MarkerFaceColor', colours(4,:));
xline(optBoundary, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.5);
xlabel('Boundary'); ylabel('Rate (%)');
title('Hit rate, FA rate, and confusion rate');
legend({'Hit rate', 'FA rate', 'Confusion rate'}, 'Location', 'east');
grid on; box on; hold off;

% --- Subplot 4: ROC-like scatter (FA rate vs hit rate, coloured by boundary) ---
subplot(2, 2, 4);
hold on;
scatter(faRate*100, hitRate*100, 50, bGrid, 'filled');
colormap(gca, parula);
cb = colorbar; cb.Label.String = 'Boundary';
% Diagonal (chance performance)
plot([0 100], [0 100], '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
% Mark the optimal boundary (reuse optHR/optFAR computed earlier)
plot(optFAR*100, optHR*100, 'rv', 'MarkerSize', 12, ...
     'MarkerFaceColor', [0.8 0.2 0.2], 'LineWidth', 1.5);
text(optFAR*100 + 1, optHR*100 - 3, sprintf('b = %.2f', optBoundary), ...
     'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.8 0.2 0.2]);
xlabel('False alarm rate (%)'); ylabel('Hit rate (%)');
title('ROC space (each point = one boundary)');
axis([0 100 0 100]); axis square;
grid on; box on; hold off;

sgtitle('Signal Detection Theory Analysis', 'FontSize', 14, 'FontWeight', 'bold');

% ---- Figure C: MCMC Posterior (4 panels) ----

figure('Name', 'MCMC Posterior', 'NumberTitle', 'off', ...
       'Position', [100, 60, 1000, 700]);

% --- Subplot 1: MCMC trace plot ---
%  Burn-in is handled internally by slicesample, so the chain here is
%  entirely post-burn-in samples.
subplot(2, 2, 1);
hold on;
plot(1:nPosterior, mcmcChain, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.3);
yline(posteriorMean, '-', 'Color', colours(1,:), 'LineWidth', 1.5);
xlabel('Post-burn-in sample'); ylabel('Boundary');
title(sprintf('Trace plot (%d samples, thin=2)', nPosterior));
legend({'Chain', 'Post. mean'}, 'Location', 'northeast', 'FontSize', 7);
grid on; box on; hold off;

% --- Subplot 2: Posterior histogram with CIs ---
subplot(2, 2, 2);
hold on;
histogram(mcmcChain, 60, 'Normalization', 'pdf', ...
          'FaceColor', colours(1,:), 'FaceAlpha', 0.6, 'EdgeColor', 'none');
% 95% CI shading
yl = ylim;
fill([ci95(1), ci95(2), ci95(2), ci95(1)], ...
     [0, 0, yl(2), yl(2)], colours(1,:), 'FaceAlpha', 0.12, 'EdgeColor', 'none');
% 80% CI shading (darker)
fill([ci80(1), ci80(2), ci80(2), ci80(1)], ...
     [0, 0, yl(2), yl(2)], colours(1,:), 'FaceAlpha', 0.12, 'EdgeColor', 'none');
% Lines
xline(posteriorMean, '-', 'Color', [0.8 0.2 0.2], 'LineWidth', 2);
xline(posteriorMedian, '--', 'Color', [0.4 0.2 0.6], 'LineWidth', 1.5);
xline(mapBoundary, ':', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
xline(exp(priorMu), '-.', 'Color', [0.6 0.4 0.1], 'LineWidth', 1.2);
xlabel('Boundary'); ylabel('Posterior density');
title('Posterior distribution p(boundary | data)');
legend({'Posterior', '95% CI', '80% CI', ...
        sprintf('Mean = %.2f', posteriorMean), ...
        sprintf('Median = %.2f', posteriorMedian), ...
        sprintf('MAP = %.2f', mapBoundary), ...
        sprintf('Prior mean = %.2f', exp(priorMu))}, ...
       'Location', 'northeast', 'FontSize', 7);
grid on; box on; hold off;

% --- Subplot 3: Posterior predictive - accuracy and latency ---
%  For each posterior sample, interpolate the expected accuracy and latency
nPredSamples = min(nPosterior, 2000);  % subsample for speed
predIdx = randperm(nPosterior, nPredSamples);
predAcc = interp1(bGrid, accVec, mcmcChain(predIdx), 'pchip');
predLat = interp1(bGrid, latVec, mcmcChain(predIdx), 'pchip');

subplot(2, 2, 3);
hold on;
scatter(predLat, predAcc * 100, 8, colours(1,:), 'filled', 'MarkerFaceAlpha', 0.15);
% Overlay the MC grid points
scatter(latVec, accVec * 100, 40, optCfg.boundaryGrid, 'filled');
colormap(gca, parula);
cb = colorbar; cb.Label.String = 'Boundary';
% Mark posterior mean (reuse optAcc/optLat computed earlier)
plot(optLat, optAcc * 100, 'rv', 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.2 0.2], 'LineWidth', 1.5);
text(optLat + 0.05, optAcc * 100 - 1.5, ...
     sprintf('mean = %.2f', posteriorMean), ...
     'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.8 0.2 0.2]);
xlabel('Mean latency (s)'); ylabel('Accuracy (%)');
title('Speed-accuracy tradeoff (posterior samples)');
grid on; box on; hold off;

% --- Subplot 4: Running posterior mean (convergence check) ---
subplot(2, 2, 4);
hold on;
runningMean = cumsum(mcmcChain) ./ (1:nPosterior)';
runningQ025 = zeros(nPosterior, 1);
runningQ975 = zeros(nPosterior, 1);
% Compute running quantiles at log-spaced intervals for speed
checkPts = unique([1:10, round(logspace(1, log10(nPosterior), 200))]);
checkPts = checkPts(checkPts <= nPosterior);
for ci = 1:numel(checkPts)
    idx = checkPts(ci);
    q = quantile(mcmcChain(1:idx), [0.025, 0.975]);
    runningQ025(idx) = q(1);
    runningQ975(idx) = q(2);
end
% Interpolate gaps
runningQ025 = interp1(checkPts, runningQ025(checkPts), 1:nPosterior, 'linear', 'extrap');
runningQ975 = interp1(checkPts, runningQ975(checkPts), 1:nPosterior, 'linear', 'extrap');

xAxis = 1:nPosterior;
fill([xAxis, fliplr(xAxis)], [runningQ025, fliplr(runningQ975)], ...
     colours(1,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(xAxis, runningMean, '-', 'Color', colours(1,:), 'LineWidth', 1.5);
yline(posteriorMean, '--', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.0);
xlabel('Post-burn-in sample'); ylabel('Boundary');
title('Convergence: running mean + 95% CI');
legend({'Running 95% CI', 'Running mean', 'Final mean'}, ...
       'Location', 'northeast', 'FontSize', 7);
grid on; box on; hold off;

sgtitle(sprintf(['MCMC Posterior: boundary = %.2f [%.2f, %.2f]_{95%%}  ' ...
                 '(prior = %.2f,  MAP = %.2f)'], ...
        posteriorMean, ci95(1), ci95(2), exp(priorMu), mapBoundary), ...
        'FontSize', 13, 'FontWeight', 'bold');

%% ====== PLOT: LCA RACE WITH OPTIMISED BOUNDARY vs DEFAULT ======
%  Use evidence values that match the MC simulation distributions
%  (3 accumulators, realistic overlap) so the demo is representative.

figure('Name', 'Optimised vs Default Boundary', 'NumberTitle', 'off', ...
       'Position', [120, 80, 1000, 450]);

rhoDemo = [rhoTarget, rhoDistract, rhoDistract];  % typical "looking at 15 Hz" trial
demoTMax = 5.0;           % long enough for default boundary to maybe cross

rng(123);  % same noise for both
[tVec1, xMat1, w1, ct1] = runLCA(rhoDemo, params, demoTMax);

rng(123);  % reset so same noise sequence
pOpt = params;
pOpt.boundary = optBoundary;
[tVec2, xMat2, w2, ct2] = runLCA(rhoDemo, pOpt, demoTMax);

% Shared y-axis limit so both panels are visually comparable
yMax = max([max(xMat1(:)), max(xMat2(:)), params.boundary, optBoundary]) * 1.15;

% Left: default boundary
subplot(1, 2, 1);
hold on;
for ai = 1:numel(rhoDemo)
    plot(tVec1, xMat1(:,ai), 'Color', colours(ai,:), 'LineWidth', 2);
end
yline(params.boundary, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2);
if w1 > 0
    plot(ct1, params.boundary, 'kd', 'MarkerSize', 10, ...
         'MarkerFaceColor', colours(w1,:));
    text(ct1 + 0.08, params.boundary - 0.15, ...
         sprintf('%s wins @ %.2fs', freqLabels{w1}, ct1), ...
         'FontWeight', 'bold', 'FontSize', 9);
else
    text(demoTMax * 0.3, params.boundary * 0.5, 'No decision (HOLD)', ...
         'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.6 0.1 0.1]);
end
ylim([0 yMax]);
xlabel('Time (s)'); ylabel('Activation');
title(sprintf('Default boundary = %.1f', params.boundary));
legend(freqLabels, 'Location', 'northwest');
grid on; box on;
hold off;

% Right: optimised boundary
subplot(1, 2, 2);
hold on;
for ai = 1:numel(rhoDemo)
    plot(tVec2, xMat2(:,ai), 'Color', colours(ai,:), 'LineWidth', 2);
end
yline(optBoundary, '--', 'Color', [0.8 0.2 0.2], 'LineWidth', 1.2);
if w2 > 0
    plot(ct2, optBoundary, 'kd', 'MarkerSize', 10, ...
         'MarkerFaceColor', colours(w2,:));
    text(ct2 + 0.08, optBoundary - 0.05, ...
         sprintf('%s wins @ %.2fs', freqLabels{w2}, ct2), ...
         'FontWeight', 'bold', 'FontSize', 9);
else
    text(demoTMax * 0.3, optBoundary * 0.5, 'No decision (HOLD)', ...
         'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.6 0.1 0.1]);
end
ylim([0 yMax]);
xlabel('Time (s)'); ylabel('Activation');
title(sprintf('MCMC posterior mean boundary = %.2f', optBoundary));
legend(freqLabels, 'Location', 'northwest');
grid on; box on;
hold off;

sgtitle(sprintf('Same trial (\\rho = [%.2f, %.2f, %.2f]), different boundaries', ...
        rhoDemo(1), rhoDemo(2), rhoDemo(3)), 'FontSize', 14, 'FontWeight', 'bold');

fprintf('\nAll figures created.\n');

%% ==================== LCA SIMULATION FUNCTION ====================

function [tVec, xMat, winner, crossTime] = runLCA(rho, p, tMax)
% runLCA  Simulate a leaky competing accumulator trial (full trajectories).
%
%   [tVec, xMat, winner, crossTime] = runLCA(rho, params, tMax)
%
%   Implements Usher & McClelland (2001) Eq. 4:
%     dx_i = [rho_i - k*x_i - beta*sum(x_j, j!=i)] * dt/tau
%            + sigma * xi_i * sqrt(dt/tau)
%     x_i  -> max(x_i, 0)
%
%   Stores full trajectories for plotting. For MC simulations where only
%   the outcome matters, use runLCA_fast instead.

    nAccum  = numel(rho);
    nSteps  = ceil(tMax / p.dt);
    dtTau   = p.dt / p.tau;
    sqDtTau = sqrt(dtTau);

    tVec = (0:nSteps)' * p.dt;
    xMat = zeros(nSteps + 1, nAccum);

    x = zeros(1, nAccum);
    winner    = 0;
    crossTime = NaN;

    for s = 1:nSteps
        totalX = sum(x);
        inhib  = p.beta * (totalX - x);
        drive  = (rho - p.k * x - inhib) * dtTau;
        noise  = p.sigma * randn(1, nAccum) * sqDtTau;
        x = max(x + drive + noise, 0);
        xMat(s + 1, :) = x;

        % Check boundary crossing (keep simulating for trajectory plot)
        if winner == 0 && any(x >= p.boundary)
            crossed = find(x >= p.boundary);
            [~, best] = max(x(crossed));
            winner    = crossed(best);
            crossTime = s * p.dt;
        end
    end
end

function [winner, crossTime] = runLCA_fast(rho, p, tMax)
% runLCA_fast  Lightweight LCA for Monte Carlo -- no trajectory storage.
%   Returns only the winner index (0 = HOLD) and crossing time (NaN if none).
%   Exits immediately on first boundary crossing for maximum speed.

    nAccum  = numel(rho);
    nSteps  = ceil(tMax / p.dt);
    dtTau   = p.dt / p.tau;
    sqDtTau = sqrt(dtTau);

    x = zeros(1, nAccum);
    winner    = 0;
    crossTime = NaN;

    for s = 1:nSteps
        totalX = sum(x);
        inhib  = p.beta * (totalX - x);
        drive  = (rho - p.k * x - inhib) * dtTau;
        noise  = p.sigma * randn(1, nAccum) * sqDtTau;
        x = max(x + drive + noise, 0);

        % Early exit on first boundary crossing
        if any(x >= p.boundary)
            crossed = find(x >= p.boundary);
            [~, best] = max(x(crossed));
            winner    = crossed(best);
            crossTime = s * p.dt;
            return;
        end
    end
end

function out = iff(cond, a, b)
% iff  Inline conditional (ternary operator substitute).
    if cond
        out = a;
    else
        out = b;
    end
end

function lp = logPosteriorFn(b, gpModel, gpScale, priorLogPdf, bLo, bHi)
% logPosteriorFn  Log-posterior for boundary, with positivity constraint.
%   Returns -Inf for b <= 0 (boundary must be positive).
%   Clamps b to [bLo, bHi] before GP prediction to avoid extrapolation.
    if b <= 0
        lp = -Inf;
        return;
    end
    bClamped = max(min(b, bHi), bLo);
    lp = gpScale * predict(gpModel, bClamped) + priorLogPdf(b);
end

function label = sdtCriterionLabel(c)
% sdtCriterionLabel  Return a text label for the SDT criterion value.
    if c > 0.1
        label = 'conservative';
    elseif c < -0.1
        label = 'liberal';
    else
        label = 'neutral';
    end
end            