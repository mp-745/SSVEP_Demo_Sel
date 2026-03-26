function POWER = SimSSVEP(EPOCHS,METHOD_PARAMS,EEG_PARAMS)

trials = EPOCHS.epochs;
for tr=1:length(trials)
    for ep=1:size(trials{tr},3)
        [power{tr}(ep,:)] = RT_SSVEP(trials{tr}(EEG_PARAMS.electrodes,:,ep),EEG_PARAMS,METHOD_PARAMS);
    end
end

POWER = EPOCHS;
POWER = rmfield(POWER,'epochs');
POWER.power = power;

end