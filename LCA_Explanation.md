# Leaky Competing Accumulator (LCA) for SSVEP Drone Control

## What Problem Does This Solve?

The original `droneSSVEP.m` uses a consensus + confidence threshold approach: classify each EEG window independently, then require N consecutive windows to agree with sufficient confidence before sending a command. This has a few issues for drone control:

1. A single noisy classification in the middle breaks the consensus chain and resets the counter
2. Commands are sent at variable intervals (whenever consensus happens to be met)
3. It only uses one classifier at a time, discarding the others
4. There's no formal model of how evidence should accumulate over time

The LCA replaces all of this with a single, principled decision mechanism borrowed from computational neuroscience.

---

## What Is a Drift-Diffusion Model?

Imagine you're trying to decide between two options. Evidence for each option arrives over time. A drift-diffusion model (DDM) tracks a single decision variable that starts at zero and drifts up or down as evidence comes in. If it drifts high enough (crosses the upper boundary), you choose option A. If it drifts low enough (crosses the lower boundary), you choose option B.

The DDM is the standard model of how the brain makes two-alternative decisions. It's mathematically equivalent to the Sequential Probability Ratio Test (SPRT), which is the optimal procedure for sequential hypothesis testing -- meaning it reaches a given accuracy in the fewest possible observations.

The problem: a basic DDM only handles two choices. We need three (or more) for multiple drone directions.

---

## From DDM to LCA: Handling 3+ Choices

The Leaky Competing Accumulator (Usher & McClelland, 2001) generalizes the DDM to any number of alternatives. Instead of one decision variable drifting between two boundaries, you have N separate accumulators, one per choice, each racing toward its own boundary.

For our 3-stimulus SSVEP system (e.g., x Hz, 15 Hz, 20 Hz), there are three accumulators:

```
Accumulator 1 (x Hz / FORWARD):   ████████████░░░░░░░░░░ 58% to boundary
Accumulator 2 (15 Hz / LEFT):     ██░░░░░░░░░░░░░░░░░░░░ 11% to boundary
Accumulator 3 (20 Hz / RIGHT):    ███░░░░░░░░░░░░░░░░░░░ 15% to boundary
```

The first one to reach its boundary wins, and that command gets sent.

---

## The LCA Update Equation

The update follows Usher & McClelland (2001), Equation 4 (p. 559). Each time new evidence arrives (every classifier output), the accumulators update:

$$dx_i = \left[\rho_i - k \, x_i - \beta \sum_{j \neq i} x_j \right] \frac{dt}{\tau} + \sigma \, \xi_i \, \sqrt{\frac{dt}{\tau}}$$

$$x_i \leftarrow \max(x_i, \; 0)$$

There are five components, plus the nonlinear floor:

**Input ($\rho_i$)**: The external evidence for accumulator $i$. In our case this is the combined correlation value from all classifiers for frequency $i$. Strong SSVEP signal at that frequency means strong input. This is the "drift" in drift-diffusion.

**Leak ($k \, x_i$)**: Pulls each accumulator back toward zero. The paper defines $k$ as the *net* leak, which is actually two mechanisms combined: passive decay ($\lambda$) and recurrent self-excitation ($\alpha$), where $k = \lambda - \alpha$. When $k > 0$, accumulated evidence decays over time, so if Daisy looks at the 15 Hz stimulus and then looks away, that accumulator fades back down. When $k < 0$ (self-excitation exceeds decay), the system self-amplifies, which we don't want for BCI, so we keep $k$ positive.

**Inhibition ($\beta \sum_{j \neq i} x_j$)**: Lateral competition between accumulators. When the xHz accumulator is high, it pushes the 15 Hz and 20 Hz accumulators down. This creates a winner-take-all dynamic: strong evidence for one choice actively suppresses the others. The paper specifically uses lateral inhibition rather than feed-forward inhibition because it scales naturally to any number of alternatives and matches neurophysiological evidence about how competition works in cortex.

**Time scale ($dt / \tau$)**: The deterministic part is scaled by $dt/\tau$, where $\tau$ is the integration time constant. This separates the step size ($dt$, set by how often your classifiers produce output) from the dynamics of the model ($\tau$). Smaller $\tau$ means faster dynamics relative to the evidence arrival rate.

**Noise ($\sigma \, \xi_i \, \sqrt{dt/\tau}$)**: Gaussian noise scaled by the square root of $dt/\tau$. The square root scaling is important: it comes from the fact that the variance of uncorrelated random variables is additive, so the standard deviation grows as $\sqrt{t}$. If you scale noise the same way as the deterministic part (by $dt/\tau$ instead of $\sqrt{dt/\tau}$), noise gets too small at small time steps and too large at large ones. In a BCI context the EEG signal is already noisy, but this term prevents accumulators from getting stuck and makes the model more robust.

**Floor at zero ($x_i \leftarrow \max(x_i, 0)$)**: This is the threshold-linear nonlinearity. Once an accumulator drops to zero it's effectively out of the race -- it can't go negative and pull itself back up through inhibition on the others. This is what makes the model nonlinear and is critical for the winner-take-all dynamics to work properly.

Below is a demonstration of how the leaky competing accumulator will perform in various scenarios (different parameter estimates & different incoming signals):

![[Pasted image 20260404142143.png]]

---

## Fixed-Window Operation (How It Fits Drone Control)

In the original DDM literature, the process runs until a boundary is crossed (variable reaction time). For drone control, we need fixed-interval commands. We need exactly one command every T seconds (e.g., 0.5s).

Here's how each command window works:

```
Command Window (T = 0.5s)
Time:  0.0s    0.1s    0.2s    0.3s    0.4s    0.5s
       |-------|-------|-------|-------|-------|
       reset   step    step    step    step    DECIDE
       LCA     1       2       3       4       & SEND

Each "step" = all 4 classifiers run on latest EEG window
            = 4 correlation vectors combined into 1 evidence vector
            = evidence vector fed into LCA
```

At the end of the window, there are two possible outcomes:

1. **A boundary was crossed** (possibly early): Send that command. The drone moves in that direction for T seconds.
2. **No boundary was crossed**: Send HOLD (command 0). The drone stays in place for T seconds.

If a boundary is crossed early (say at step 2 out of 4), the system notes it but still waits until the end of the window to send. The next window starts with a fresh reset. This keeps command timing perfectly regular.

---

## Visualizing the Race

Below shows a simulation of what happens inside the LCA during a command window:

![[Pasted image 20260404141114.png]]
When Daisy is clearly looking at the 15 Hz stimulus, that accumulator climbs steadily while the others get suppressed. When she's not focused on anything, all three wander around the bottom and none reaches the boundary resulting in a HOLD command. 

However as you may have noticed, I left in an arbitrary boundary, so every classification will end in a HOLD. Later, we will use some MCMC to select the best parameter estimates for the activation threshold, and get some signal detection theory information about the summary statistics at the "best" threshold.

---
### Tuning Strategy

We will start with the default boundary. Then:

1. If too many false commands (drone moves when it shouldn't): raise `boundary`
2. If too many HOLDs (drone never moves even when Daisy is looking): lower `boundary`
3. If the drone keeps moving after Daisy looks away: raise `leak`
4. If decisions are noisy with unclear gaze: raise `inhibition`
5. Adjust `commandWindowSec` for the responsiveness vs accuracy trade-off

---
## Bayesian Boundary Estimation (MCMC)

The boundary is the most important parameter in the LCA. Too high and Daisy never triggers a command (all HOLDs). Too low and the system fires on noise (wrong commands, bad for a drone). We use Bayesian inference to find the right boundary from data rather than guessing.
### The problem

The boundary controls the speed-accuracy trade-off. The relationship between boundary and performance isn't something you can solve analytically because it depends on the actual signal quality, noise levels, and how the classifiers behave on Daisy's EEG. So, we should measure it, to make sure that we don't assume where the boundary should be arbitrarily.
### Diagnostics

The visualisation script (`lca_visualisation.m`) produces three sets of diagnostic figures:

**Figure A: MC simulation results (4 panels)**

1. **Accuracy vs boundary**: overall correct classification rate at each grid point, with the posterior mean boundary marked.
2. **Latency vs boundary**: mean decision time (only over trials where the LCA fired, not HOLDs).
3. **Error rate and HOLD rate**: shows the trade-off: lower boundaries increase errors, higher boundaries increase HOLDs.
4. **GP surrogate + prior**: the fitted GP mean with uncertainty band, observed MC utility values, and the scaled log-normal prior.
![[Pasted image 20260404142432.png]]

**Figure B: Signal Detection Theory (4 panels)**

1. **$d'$ (sensitivity) vs boundary**: how well the LCA discriminates signal from noise at each boundary. $d' > 2.0$ is strong, $1.0$-$2.0$ is moderate, $< 1.0$ is weak.
2. **Criterion ($c$) vs boundary**: the response bias. Positive $c$ (conservative) means the system favours HOLDs over false alarms; negative $c$ (liberal) means it fires readily. For drone control, conservative is safer. Background shading shows the conservative (blue) and liberal (red) regions.
3. **Hit rate, FA rate, and confusion rate**: the three error types broken down. Hit rate is correct detections on signal trials, FA rate is false detections on rest trials, confusion rate is picking the wrong frequency on signal trials.
4. **ROC space**: each boundary plotted as (FA rate, hit rate), coloured by boundary value. The diagonal is chance performance. Points toward the upper-left corner are better.
![[Pasted image 20260404142450.png]]
(N.B I feel like some of these are a bit messy and I prefer looking at the summary stats)

```{matlab}
=== SIGNAL DETECTION THEORY ===
At best MC boundary (0.88):  
Hit rate: 56.9% (9103 / 16000 signal trials)  
Miss rate: 43.1% (HOLD on signal)  
Confusion rate: 10.4% (wrong class on signal)  
FA rate: 12.2% (487 / 4000 noise trials)  
d' = 1.34  
c = 0.50 (conservative)
Interpretation:
d' = 1.34: moderate discriminability. Some signal/noise overlap.  
Confusion rate > 10%: the LCA often picks the wrong class.  
This suggests the two SSVEP evidence streams are not well separated.

--- SDT at posterior mean ---  
d' = 1.63, c = 1.00 (conservative)  
Hit rate = 42.5%, FA rate = 3.5%, Confusion rate = 4.6%
```

**Figure C: MCMC posterior (4 panels)**
1. **Trace plot**: the slice sampling chain over post-burn-in iterations. Should look like a fuzzy caterpillar (good mixing). Since slice sampling auto-tunes the step size, there's no acceptance rate to monitor.
2. **Posterior histogram**: the distribution of boundary values after burn-in, with 80% and 95% credible intervals shaded, and the mean/median/MAP/prior marked.
3. **Speed-accuracy scatter**: for each posterior sample, the corresponding accuracy and latency interpolated from the MC grid. Shows the range of operating points consistent with the posterior.
4. **Convergence plot**: running posterior mean and 95% CI over samples. Should flatten out, meaning the chain has converged.
![[Pasted image 20260404142742.png]]

```
--- MCMC Results ---  
Posterior mean boundary: 1.01  
Posterior median boundary: 0.96  
Posterior SD: 0.42  
95% credible interval: [0.77, 1.27]  
80% credible interval: [0.84, 1.11]  
MAP boundary (comparison): 0.94  
Raw MC best boundary: 0.88  
Prior mean boundary: 3.00  
Utility at posterior mean: -0.171  
Accuracy at posterior mean: ~34.0%  
Mean latency at post. mean: ~2.37s  
x_ss / boundary = 4.29 (>1 = reachable)
```

**Figure D: Optimised vs default boundary**: same LCA trial run twice with different boundaries (default 3.0 vs posterior mean). Shows the 3 accumulator traces and whether/when each boundary is crossed.

Below is what happens now that we're cooking on MCMC:
![[Pasted image 20260404141720.png]]

---
## Signal Detection Theory (SDT) Analysis

The MC simulation also computes signal detection theory metrics at each boundary. This gives a deeper picture than raw accuracy because it separates the system's ability to discriminate signal from noise (sensitivity, $d'$) from its tendency to fire or hold (response bias, criterion $c$).

For a BCI with 3 target frequencies plus rest, the SDT framing is:

- **Signal trial**: Daisy is looking at any target (trueClass = 1, 2, or 3)
- **Noise trial**: Daisy is at rest (trueClass = 0)
- **Hit**: signal trial where the correct class was detected
- **Miss**: signal trial where the LCA held (no boundary crossing)
- **Confusion**: signal trial where the wrong class was detected (e.g., looking at 15 Hz but 20 Hz accumulator won)
- **False alarm**: noise trial where any accumulator crossed the boundary
- **Correct rejection**: noise trial where the LCA held

Confusions are counted separately from misses because they represent different failure modes. A miss means "I'm not sure" (safe for a drone); a confusion means "go the wrong way" (dangerous).

### $d'$ and criterion

$d'$ (d-prime) measures how well the system separates signal from noise, independent of the boundary setting:

$$d' = \Phi^{-1}(\text{hit rate}) - \Phi^{-1}(\text{FA rate})$$

where $\Phi^{-1}$ is the inverse normal CDF. Higher $d'$ means better discriminability. For drone control: $d' > 2.0$ is strong, $1.0 < d' < 2.0$ is moderate, $d' < 1.0$ is too weak to be useful.

The criterion $c$ measures response bias:

$$c = -\frac{1}{2} \left[\Phi^{-1}(\text{hit rate}) + \Phi^{-1}(\text{FA rate})\right]$$

Positive $c$ means conservative (favours HOLDs over false alarms), negative $c$ means liberal (fires readily). For drone control, conservative bias is safer.
### Realistic Performance (3-class, noisy EEG)

With the realistic $\rho$ distributions ($\rho_{\text{target}} = 0.45$, $\rho_{\text{distractor}} = 0.28$, $\rho_{\text{rest}} = 0.25$) and 3 accumulators, the simulation gives these results at the optimal boundary ($b \approx 0.88$-$1.01$):

| Metric         | Value | Interpretation                                               |
| -------------- | ----- | ------------------------------------------------------------ |
| $d'$           | 1.36  | Moderate discriminability. Signal and noise overlap.         |
| $c$            | 0.51  | Conservative. System prefers HOLDs over false alarms.        |
| Hit rate       | 57%   | Just over half of target looks are correctly detected.       |
| Miss rate      | 43%   | Nearly half of target looks result in HOLD (safe but slow).  |
| Confusion rate | 10%   | 1 in 10 signal trials picks the wrong frequency (dangerous). |
| FA rate        | 12%   | 1 in 8 rest trials triggers a false command.                 |
| Accuracy       | 33%   | Overall correct rate including rest trials.                  |
| Latency        | ~2.4s | Mean time to decision on trials where the LCA fired.         |
| Utility        | -0.17 | Negative: the error cost outweighs the accuracy benefit.     |

